import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../providers/browser_provider.dart';
import '../providers/history_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/settings_provider.dart';
import '../services/browser_engine.dart';
import '../services/database_service.dart';
import '../theme/tokens.dart';
import '../widgets/ui/tv_widgets.dart';
import '../utils/url_utils.dart';

/// Privacy dashboard: connection status, data clearing and tracking controls.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _clearCookies(BuildContext context) async {
    try {
      await CookieManager.instance().deleteAllCookies();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cookies cleared')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not clear cookies')),
      );
    }
  }

  Future<void> _clearWebStorage(BuildContext context) async {
    final browser = context.read<BrowserProvider>();
    var cleared = 0;
    for (final tab in browser.tabs) {
      final controller = tab.controller;
      if (controller == null) continue;
      try {
        await controller.evaluateJavascript(
            source: BrowserEngine.clearWebStorageScript);
        cleared++;
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Local storage cleared on $cleared tab(s)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final browser = context.watch<BrowserProvider>();
    final permissions = context.watch<PermissionProvider>();
    final tab = browser.activeTab;
    final secure = UrlUtils.isSecure(tab?.url ?? '');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              TvSpace.page,
              TvSpace.sm,
              TvSpace.page,
              0,
            ),
            padding: const EdgeInsets.all(TvSpace.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(TvRadius.md),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(secure ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: secure
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        secure ? 'Secure connection (HTTPS)' : 'Not secure',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tab?.url.isEmpty ?? true
                        ? 'Open a page to see its connection details.'
                        : UrlUtils.hostOf(tab!.url),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const TvSectionHeader(title: 'Tracking and content'),
          SwitchListTile(
            secondary: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Do Not Track'),
            subtitle: const Text(
                'Sends the DNT signal. It is a request, not a guarantee.'),
            value: settings.settings.doNotTrack,
            onChanged: settings.setDoNotTrack,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.code_rounded),
            title: const Text('JavaScript'),
            value: settings.settings.javaScriptEnabled,
            onChanged: settings.setJavaScriptEnabled,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.cookie_outlined),
            title: const Text('Cookies'),
            value: settings.settings.cookiesEnabled,
            onChanged: settings.setCookiesEnabled,
          ),
          const TvSectionHeader(title: 'Clear data'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear cookies'),
            subtitle: const Text('Signs you out of websites'),
            onTap: () => _clearCookies(context),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Clear local storage'),
            subtitle: const Text('localStorage and sessionStorage per open tab'),
            onTap: () => _clearWebStorage(context),
          ),
          ListTile(
            leading: const Icon(Icons.manage_search_rounded),
            title: const Text('Clear search history'),
            subtitle: const Text('The queries kept for suggestions'),
            onTap: () async {
              await context.read<DatabaseService>().clearSearchHistory();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search history cleared')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_toggle_off_rounded),
            title: const Text('Clear browsing history'),
            onTap: () async {
              await context.read<HistoryProvider>().clearAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Reset website permissions'),
            subtitle: Text('${permissions.sites.length} stored decision(s)'),
            onTap: permissions.resetAll,
          ),
          const TvSectionHeader(title: 'Private browsing'),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              TvSpace.page,
              0,
              TvSpace.page,
              TvSpace.xl,
            ),
            child: Text(
              'Private tabs use an isolated WebView session: no history is '
              'written, cookies stay in memory, and tabs close when the app '
              'goes to background if that setting is on. Private mode does not '
              'hide your activity from websites, your internet provider or a '
              'network administrator.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
