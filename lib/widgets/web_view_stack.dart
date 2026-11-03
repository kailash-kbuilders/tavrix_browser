import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tab_model.dart';
import '../providers/browser_provider.dart';
import '../providers/download_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/settings_provider.dart';
import '../services/browser_engine.dart';
import '../services/permission_service.dart';
import '../utils/url_utils.dart';

/// Keeps one live WebView per open tab in an IndexedStack so switching tabs
/// never reloads a page.
class WebViewStack extends StatelessWidget {
  const WebViewStack({
    super.key,
    required this.tabs,
    required this.activeTabId,
  });

  final List<TabModel> tabs;
  final String? activeTabId;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.expand();
    var index = tabs.indexWhere((tab) => tab.id == activeTabId);
    if (index < 0) index = 0;
    return IndexedStack(
      index: index,
      children: [
        for (final tab in tabs)
          if (tab.isBlank)
            const SizedBox.expand()
          else
            TabWebView(
              key: ValueKey('${tab.id}-${tab.isDesktopMode}'),
              tab: tab,
            ),
      ],
    );
  }
}

/// A single tab's WebView and its callbacks into [BrowserProvider].
class TabWebView extends StatefulWidget {
  const TabWebView({super.key, required this.tab});

  final TabModel tab;

  @override
  State<TabWebView> createState() => _TabWebViewState();
}

class _TabWebViewState extends State<TabWebView> {
  InAppWebViewController? _controller;
  String? _appliedSettingsSignature;

  /// Settings that can be changed while a page is open. Changing them used to
  /// require closing the tab, so switches like JavaScript or cookies looked
  /// broken. The signature lets us push new settings to the live WebView.
  String _signature(InAppWebViewSettings settings) => [
        settings.javaScriptEnabled,
        settings.thirdPartyCookiesEnabled,
        settings.javaScriptCanOpenWindowsAutomatically,
        settings.geolocationEnabled,
        settings.userAgent,
        settings.incognito,
      ].join('|');

  Future<void> _syncNavigation(BrowserProvider browser, String tabId) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final canGoBack = await controller.canGoBack();
      final canGoForward = await controller.canGoForward();
      browser.onHistoryStateChanged(
        tabId,
        canGoBack: canGoBack,
        canGoForward: canGoForward,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final browser = context.read<BrowserProvider>();
    // watch, not read: a settings change must rebuild so it can be applied.
    final settings = context.watch<SettingsProvider>();
    final downloads = context.read<DownloadProvider>();
    final permissions = context.read<PermissionProvider>();

    final desiredSettings = BrowserEngine.settingsFor(
      appSettings: settings.settings,
      isPrivate: tab.isPrivate,
      desktopMode: tab.isDesktopMode,
    );
    final signature = _signature(desiredSettings);
    if (_appliedSettingsSignature == null) {
      _appliedSettingsSignature = signature;
    } else if (_appliedSettingsSignature != signature) {
      _appliedSettingsSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _controller?.setSettings(settings: desiredSettings);
        } catch (_) {}
      });
    }

    return InAppWebView(
      initialUrlRequest: tab.url.isEmpty
          ? null
          : URLRequest(url: WebUri(tab.url)),
      initialSettings: BrowserEngine.settingsFor(
        appSettings: settings.settings,
        isPrivate: tab.isPrivate,
        desktopMode: tab.isDesktopMode,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        browser.attachController(tab.id, controller);
      },
      onLoadStart: (controller, url) {
        browser.onLoadStart(tab.id, url?.toString());
        _syncNavigation(browser, tab.id);
      },
      onLoadStop: (controller, url) async {
        await browser.onLoadStop(tab.id, url?.toString());
        await _syncNavigation(browser, tab.id);
        if (settings.settings.doNotTrack) {
          try {
            await controller.evaluateJavascript(
                source: BrowserEngine.doNotTrackScript);
          } catch (_) {}
        }
      },
      onProgressChanged: (controller, progress) {
        browser.onProgressChanged(tab.id, progress);
      },
      onTitleChanged: (controller, title) {
        browser.onTitleChanged(tab.id, title);
      },
      onUpdateVisitedHistory: (controller, url, isReload) {
        browser.onUrlChanged(tab.id, url?.toString());
        _syncNavigation(browser, tab.id);
      },
      onReceivedError: (controller, request, error) {
        final isMainFrame = request.isForMainFrame ?? false;
        if (isMainFrame) {
          browser.onError(tab.id, error.description);
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        final isMainFrame = request.isForMainFrame ?? false;
        if (isMainFrame && (errorResponse.statusCode ?? 0) >= 400) {
          browser.onError(
              tab.id, 'Server error ${errorResponse.statusCode ?? ''}');
        }
      },
      onDownloadStartRequest: (controller, request) async {
        final url = request.url.toString();
        var filename = request.suggestedFilename ?? '';
        if (filename.trim().isEmpty) {
          final path = Uri.tryParse(url)?.pathSegments ?? const <String>[];
          filename = path.isEmpty ? 'download' : path.last;
        }
        if (filename.trim().isEmpty) filename = 'download';
        await downloads.startDownload(
          url: url,
          filename: filename,
          mimeType: request.mimeType,
          userAgent: request.userAgent,
        );
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final target = navigationAction.request.url;
        if (target == null) return NavigationActionPolicy.ALLOW;
        final uri = Uri.tryParse(target.toString());
        if (uri == null) return NavigationActionPolicy.ALLOW;
        final scheme = uri.scheme.toLowerCase();
        const internal = {
          'http',
          'https',
          'about',
          'file',
          'data',
          'blob',
          'javascript',
          'chrome',
        };
        if (internal.contains(scheme)) return NavigationActionPolicy.ALLOW;

        // Only well known schemes may leave the browser. Anything else -
        // including intent: URLs, which can start arbitrary app components -
        // is dropped instead of being launched from a web page.
        const externalAllowed = {
          'mailto',
          'tel',
          'sms',
          'smsto',
          'whatsapp',
          'geo',
          'market',
          'upi',
          'tg',
          'maps',
        };
        if (!externalAllowed.contains(scheme)) {
          return NavigationActionPolicy.CANCEL;
        }
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
        return NavigationActionPolicy.CANCEL;
      },
      onPermissionRequest: (controller, request) async {
        final host = UrlUtils.hostOf(tab.url);
        var grant = true;
        for (final resource in request.resources) {
          final name = resource.toString().toLowerCase();
          if (name.contains('camera') || name.contains('microphone')) {
            if (name.contains('camera')) {
              grant = grant &&
                  await permissions.allowSiteFeature(
                    host: host,
                    permission: 'camera',
                    requestOs: PermissionService.requestCamera,
                    hasOs: PermissionService.cameraGranted,
                  );
            }
            if (name.contains('microphone')) {
              grant = grant &&
                  await permissions.allowSiteFeature(
                    host: host,
                    permission: 'microphone',
                    requestOs: PermissionService.requestMicrophone,
                    hasOs: PermissionService.microphoneGranted,
                  );
            }
          }
        }
        return PermissionResponse(
          resources: request.resources,
          action: grant
              ? PermissionResponseAction.GRANT
              : PermissionResponseAction.DENY,
        );
      },
      onGeolocationPermissionsShowPrompt: (controller, origin) async {
        final host = UrlUtils.hostOf(origin.toString());
        final allowed = await permissions.allowSiteFeature(
          host: host,
          permission: 'location',
          requestOs: PermissionService.requestLocation,
          hasOs: PermissionService.locationGranted,
        );
        return GeolocationPermissionShowPromptResponse(
          origin: origin.toString(),
          allow: allowed,
          retain: true,
        );
      },
    );
  }
}
