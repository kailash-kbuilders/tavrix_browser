import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/offline_page.dart';
import '../models/suggestion_item.dart';
import '../models/shortcut_item.dart';
import '../providers/bookmark_provider.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../services/browser_engine.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../services/vault_service.dart';
import '../theme/tokens.dart';
import '../utils/url_utils.dart';
import '../widgets/address_bar.dart';
import '../widgets/browser_menu_sheet.dart';
import '../widgets/browser_toolbar.dart';
import '../widgets/find_in_page_bar.dart';
import '../widgets/ui/tv_widgets.dart';
import '../widgets/web_view_stack.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'permissions_screen.dart';
import 'privacy_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';
import 'tab_overview_screen.dart';

/// The main browser shell: address bar, live WebViews, toolbar and menu.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with WidgetsBindingObserver {
  final TextEditingController _findController = TextEditingController();
  final VaultService _vault = VaultService();
  final SuggestionService _suggestionService = SuggestionService();
  final GlobalKey<AddressBarState> _addressBarKey =
      GlobalKey<AddressBarState>();
  Timer? _suggestionDebounce;
  List<SuggestionItem> _suggestions = [];
  bool _addressFocused = false;
  bool _findVisible = false;
  int _findMatches = 0;
  int _findIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _suggestionDebounce?.cancel();
    _suggestionService.close();
    _findController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<BrowserProvider>().handleAppPaused();
    }
  }

  // --------------------------------------------------------------- helpers

  /// Respects the haptics preference instead of buzzing regardless.
  void _haptic() {
    if (!context.read<SettingsProvider>().settings.haptics) return;
    HapticFeedback.selectionClick();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  // ------------------------------------------------------------- navigation

  void _submitInput(String text) {
    _haptic();
    final browser = context.read<BrowserProvider>();
    final settings = context.read<SettingsProvider>();
    final tab = browser.activeTab;
    if (tab == null) return;
    final query = text.trim();
    if (query.isEmpty) return;
    final isUrl = UrlUtils.looksLikeUrl(query);
    if (!isUrl && settings.settings.savedSearchHistory) {
      // Remembered only when the user asked for it, and never for URLs.
      context.read<DatabaseService>().insertSearchQuery(query);
    }
    final url = UrlUtils.resolveInput(query, settings.searchEngine);
    if (url.isEmpty) return;
    setState(() => _suggestions = []);
    browser.navigate(tab.id, url);
  }

  void _onAddressQueryChanged(String value) {
    _suggestionDebounce?.cancel();
    final text = value.trim();
    if (text.isEmpty) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _suggestionDebounce =
        Timer(const Duration(milliseconds: 220), () => _fetchSuggestions(text));
  }

  void _onAddressFocusChanged(bool focused) {
    if (_addressFocused == focused) return;
    _addressFocused = focused;
    if (!focused && _suggestions.isNotEmpty) {
      setState(() => _suggestions = []);
    }
  }

  /// Local data first (searches, bookmarks, history, frequent sites), then the
  /// search engine's autocomplete. Never invented results.
  Future<void> _fetchSuggestions(String query) async {
    final settings = context.read<SettingsProvider>();
    final db = context.read<DatabaseService>();
    final items = <SuggestionItem>[];
    try {
      items.addAll(await db.suggestionRows(query, limit: 6));
    } catch (_) {}
    if (settings.settings.searchSuggestions) {
      final remote = await _suggestionService.remote(
        settings.searchEngine,
        query,
        limit: 5,
      );
      for (final text in remote) {
        final exists = items.any((item) =>
            (item.query ?? item.title).toLowerCase() == text.toLowerCase());
        if (exists) continue;
        items.add(SuggestionItem(
          kind: SuggestionKind.search,
          title: text,
          query: text,
        ));
      }
    }
    // A literal "go to this" row for whatever was typed.
    if (UrlUtils.looksLikeUrl(query)) {
      items.insert(
        0,
        SuggestionItem(
          kind: SuggestionKind.url,
          title: UrlUtils.normalizeUrl(query),
          url: UrlUtils.normalizeUrl(query),
        ),
      );
    }
    if (!mounted || !_addressFocused) return;
    setState(() => _suggestions = items.take(10).toList());
  }

  void _applySuggestion(SuggestionItem item) {
    final settings = context.read<SettingsProvider>();
    final target = item.url != null
        ? item.url!
        : UrlUtils.resolveInput(
            item.query ?? item.title,
            settings.searchEngine,
          );
    _addressBarKey.currentState?.applySuggestion(target);
  }

  Future<void> _toggleBookmark() async {
    final browser = context.read<BrowserProvider>();
    final bookmarks = context.read<BookmarkProvider>();
    final tab = browser.activeTab;
    if (tab == null || tab.url.isEmpty) {
      _snack('Open a page first');
      return;
    }
    final existing = bookmarks.forUrl(tab.url);
    if (existing != null) {
      await bookmarks.remove(existing);
      _snack('Bookmark removed');
    } else {
      await bookmarks.add(title: tab.title, url: tab.url);
      _snack('Bookmark added');
    }
  }

  Future<void> _sharePage() async {
    final tab = context.read<BrowserProvider>().activeTab;
    if (tab == null || tab.url.isEmpty) {
      _snack('Nothing to share yet');
      return;
    }
    await Share.share('${tab.title}\n${tab.url}', subject: tab.title);
  }

  void _showPageInfo() {
    final tab = context.read<BrowserProvider>().activeTab;
    if (tab == null) return;
    final host = UrlUtils.hostOf(tab.url);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Page information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Title', tab.title.isEmpty ? '-' : tab.title),
            _infoRow('URL', tab.url.isEmpty ? 'New tab' : tab.url),
            _infoRow('Domain', host.isEmpty ? '-' : host),
            _infoRow(
              'Connection',
              UrlUtils.isSecure(tab.url) ? 'Secure (HTTPS)' : 'Not secure',
            ),
            const SizedBox(height: 12),
            Text(
              'Certificate checks are handled by the Android System WebView. '
              'Tavrix never bypasses an invalid certificate.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- find in page

  Future<void> _runFind(String query) async {
    final controller = context.read<BrowserProvider>().activeTab?.controller;
    if (controller == null) return;
    try {
      final result = await controller.evaluateJavascript(
          source: BrowserEngine.findInPageScript(query));
      final count = (num.tryParse(result?.toString() ?? '0') ?? 0).toInt();
      setState(() {
        _findMatches = count;
        _findIndex = 0;
      });
      if (count > 0) {
        await controller.evaluateJavascript(
            source: BrowserEngine.scrollToMatchScript(0));
      }
    } catch (_) {
      setState(() {
        _findMatches = 0;
        _findIndex = 0;
      });
    }
  }

  Future<void> _stepFind(int direction) async {
    if (_findMatches == 0) return;
    final controller = context.read<BrowserProvider>().activeTab?.controller;
    if (controller == null) return;
    var next = _findIndex + direction;
    if (next < 0) next = _findMatches - 1;
    if (next >= _findMatches) next = 0;
    setState(() => _findIndex = next);
    try {
      await controller.evaluateJavascript(
          source: BrowserEngine.scrollToMatchScript(next));
    } catch (_) {}
  }

  Future<void> _closeFind() async {
    final controller = context.read<BrowserProvider>().activeTab?.controller;
    setState(() {
      _findVisible = false;
      _findMatches = 0;
      _findIndex = 0;
    });
    _findController.clear();
    if (controller == null) return;
    try {
      await controller.evaluateJavascript(
          source: BrowserEngine.findInPageScript(''));
    } catch (_) {}
  }

  // ------------------------------------------------------- page features

  Future<void> _openReader() async {
    final tab = context.read<BrowserProvider>().activeTab;
    final controller = tab?.controller;
    if (tab == null || controller == null) {
      _snack('Open a page first');
      return;
    }
    try {
      final raw = await controller.evaluateJavascript(
          source: BrowserEngine.readerExtractionScript);
      final data = _decodeJson(raw);
      final text = (data['text'] as String? ?? '').trim();
      if (text.length < 200) {
        _snack('No readable article found on this page');
        return;
      }
      _open(ReaderScreen(
        title: (data['title'] as String? ?? tab.title).trim(),
        byline: (data['byline'] as String? ?? '').trim(),
        text: text,
        url: tab.url,
      ));
    } catch (_) {
      _snack('Could not open reader mode');
    }
  }

  Map<String, dynamic> _decodeJson(dynamic raw) {
    if (raw == null) return {};
    try {
      var value = raw;
      if (value is String) {
        value = jsonDecode(value);
        if (value is String) value = jsonDecode(value);
      }
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {}
    return {};
  }

  Future<void> _saveOffline() async {
    final tab = context.read<BrowserProvider>().activeTab;
    final controller = tab?.controller;
    if (tab == null || controller == null || tab.url.isEmpty) {
      _snack('Open a page first');
      return;
    }
    try {
      final raw = await controller.evaluateJavascript(
          source: BrowserEngine.savePageScript);
      var html = raw?.toString() ?? '';
      if (html.startsWith('"') && html.endsWith('"')) {
        html = jsonDecode(html) as String;
      }
      if (html.trim().isEmpty) {
        _snack('This page could not be saved');
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final offlineDir = Directory(p.join(directory.path, 'offline'));
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      final fileName =
          'page_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File(p.join(offlineDir.path, fileName));
      await file.writeAsString(html);
      await context.read<DatabaseService>().saveOfflinePage(OfflinePage(
            title: tab.title,
            url: tab.url,
            filePath: file.path,
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ));
      _snack('Page saved for offline reading');
    } catch (_) {
      _snack('Could not save this page');
    }
  }

  Future<void> _translatePage() async {
    final tab = context.read<BrowserProvider>().activeTab;
    final settings = context.read<SettingsProvider>();
    if (tab == null || tab.url.isEmpty) {
      _snack('Open a page first');
      return;
    }
    final target = settings.settings.translationLanguage;
    final url =
        'https://translate.google.com/translate?sl=auto&tl=$target&u=${Uri.encodeComponent(tab.url)}';
    await context.read<BrowserProvider>().navigate(tab.id, url);
  }

  Future<void> _addToHome() async {
    final tab = context.read<BrowserProvider>().activeTab;
    final db = context.read<DatabaseService>();
    if (tab == null || tab.url.isEmpty) {
      _snack('Open a page first');
      return;
    }
    final existing = await db.shortcuts();
    await db.insertShortcut(ShortcutItem(
      title: tab.title.isEmpty ? UrlUtils.suggestTitle(tab.url) : tab.title,
      url: tab.url,
      position: existing.length,
    ));
    _snack('Added to home screen');
    if (mounted) setState(() {});
  }

  Future<void> _autofill() async {
    final tab = context.read<BrowserProvider>().activeTab;
    final controller = tab?.controller;
    if (tab == null || controller == null) {
      _snack('Open a page first');
      return;
    }
    final host = UrlUtils.hostOf(tab.url);
    final credentials = await _vault.forHost(host);
    if (credentials.isEmpty) {
      _snack('No saved login for $host');
      return;
    }
    final credential = credentials.first;
    try {
      final filled = await controller.evaluateJavascript(
        source: BrowserEngine.autofillScript(
            credential.username, credential.password),
      );
      _snack(filled == true ? 'Login filled' : 'No login form found');
    } catch (_) {
      _snack('Could not fill the form');
    }
  }

  // ------------------------------------------------------------------ menu

  Future<void> _openMenu() async {
    final browser = context.read<BrowserProvider>();
    final tab = browser.activeTab;
    final host = UrlUtils.hostOf(tab?.url ?? '');
    final credentials = await _vault.forHost(host);

    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // A menu, not a page: it takes ~60% of the screen, scrolls if needed and
      // the page stays visible behind it.
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.66,
      ),
      builder: (sheetContext) => BrowserMenuSheet(
        isDesktopMode: tab?.isDesktopMode ?? false,
        isPrivate: tab?.isPrivate ?? false,
        canAutofill: credentials.isNotEmpty,
        onSelected: (action) => _handleMenuAction(action),
      ),
    );
  }

  Future<void> _handleMenuAction(BrowserMenuAction action) async {
    final browser = context.read<BrowserProvider>();
    final tab = browser.activeTab;
    switch (action) {
      case BrowserMenuAction.newTab:
        browser.openTab();
        break;
      case BrowserMenuAction.newPrivateTab:
        browser.openTab(isPrivate: true);
        break;
      case BrowserMenuAction.tabs:
        _open(const TabOverviewScreen());
        break;
      case BrowserMenuAction.bookmarks:
        _open(const BookmarksScreen());
        break;
      case BrowserMenuAction.history:
        _open(const HistoryScreen());
        break;
      case BrowserMenuAction.downloads:
        _open(const DownloadsScreen());
        break;
      case BrowserMenuAction.notifications:
        _open(const NotificationsScreen());
        break;
      case BrowserMenuAction.findInPage:
        setState(() => _findVisible = true);
        break;
      case BrowserMenuAction.translate:
        await _translatePage();
        break;
      case BrowserMenuAction.readerMode:
        await _openReader();
        break;
      case BrowserMenuAction.desktopSite:
        if (tab != null) {
          await browser.toggleDesktopMode(tab.id);
          await browser.reload(tab.id);
        }
        break;
      case BrowserMenuAction.saveOffline:
        await _saveOffline();
        break;
      case BrowserMenuAction.addToHome:
        await _addToHome();
        break;
      case BrowserMenuAction.pageInfo:
        _showPageInfo();
        break;
      case BrowserMenuAction.autofill:
        await _autofill();
        break;
      case BrowserMenuAction.share:
        await _sharePage();
        break;
      case BrowserMenuAction.privacy:
        _open(const PrivacyScreen());
        break;
      case BrowserMenuAction.sitePermissions:
        _open(const PermissionsScreen());
        break;
      case BrowserMenuAction.settings:
        _open(const SettingsScreen());
        break;
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<BrowserProvider>();
    final settings = context.watch<SettingsProvider>();
    final bookmarks = context.watch<BookmarkProvider>();
    final tab = browser.activeTab;
    final toolbarTop = settings.settings.toolbarPosition == 'top';

    final toolbar = BrowserToolbar(
      canGoBack: tab?.canGoBack ?? false,
      canGoForward: tab?.canGoForward ?? false,
      isLoading: tab?.isLoading ?? false,
      tabCount: browser.tabs.length,
      isPrivate: tab?.isPrivate ?? false,
      onBack: () {
        if (tab != null) browser.goBack(tab.id);
      },
      onForward: () {
        if (tab != null) browser.goForward(tab.id);
      },
      onReload: () {
        if (tab == null) return;
        if (tab.isLoading) {
          browser.stopLoading(tab.id);
        } else {
          browser.reload(tab.id);
        }
      },
      onHome: () {
        if (tab != null) browser.goHome(tab.id);
      },
      onTabs: () => _open(const TabOverviewScreen()),
      onMenu: _openMenu,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_addressFocused) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
          return;
        }
        if (_findVisible) {
          await _closeFind();
          return;
        }
        final active = browser.activeTab;
        if (active != null && active.canGoBack) {
          await browser.goBack(active.id);
          return;
        }
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: toolbarTop,
          child: Column(
            children: [
              if (toolbarTop) toolbar,
              AddressBar(
                key: _addressBarKey,
                onQueryChanged: _onAddressQueryChanged,
                onFocusChanged: _onAddressFocusChanged,
                tab: tab,
                isBookmarked: tab == null ? false : bookmarks.isBookmarked(tab.url),
                onSubmit: _submitInput,
                onPasteAndGo: _submitInput,
                onShowPageInfo: _showPageInfo,
                onCopy: () async {
                  final url = tab?.url ?? '';
                  if (url.isEmpty) return;
                  await Clipboard.setData(ClipboardData(text: url));
                  _snack('URL copied');
                },
                onShare: _sharePage,
                onToggleBookmark: _toggleBookmark,
                onSwipeNext: settings.settings.swipeAddressBarSwitchesTabs
                    ? () {
                        _haptic();
                        browser.switchToNextTab();
                      }
                    : () {},
                onSwipePrevious: settings.settings.swipeAddressBarSwitchesTabs
                    ? () {
                        _haptic();
                        browser.switchToPreviousTab();
                      }
                    : () {},
              ),
              if (_findVisible)
                FindInPageBar(
                  controller: _findController,
                  matches: _findMatches,
                  currentMatch: _findIndex,
                  onChanged: _runFind,
                  onNext: () => _stepFind(1),
                  onPrevious: () => _stepFind(-1),
                  onClose: _closeFind,
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: tab == null
                          ? const SizedBox.expand()
                          : tab.isBlank
                        ? HomeScreen(
                            onNavigate: (url) => browser.navigate(tab.id, url),
                            onOpenTab: (url, {bool isPrivate = false}) =>
                                browser.openTab(
                                    url: url, isPrivate: isPrivate),
                          )
                        : Stack(
                            children: [
                              WebViewStack(
                                tabs: browser.tabs,
                                activeTabId: browser.activeTabId,
                              ),
                              if (settings.settings.edgeSwipeNavigation) ...[
                                _EdgeSwipeArea(
                                  alignment: Alignment.centerLeft,
                                  onSwipe: () {
                                    _haptic();
                                    browser.goBack(tab.id);
                                  },
                                ),
                                _EdgeSwipeArea(
                                  alignment: Alignment.centerRight,
                                  onSwipe: () {
                                    _haptic();
                                    browser.goForward(tab.id);
                                  },
                                ),
                              ],
                              if ((tab.errorMessage ?? '').isNotEmpty)
                                _ErrorOverlay(
                                  message: tab.errorMessage!,
                                  onRetry: () {
                                    browser.clearError(tab.id);
                                    browser.reload(tab.id);
                                  },
                                  onGoHome: () => browser.goHome(tab.id),
                                ),
                            ],
                          ),
                    ),
                    // Suggestions sit directly under the address bar and cover
                    // the page, like Chrome. The page itself is never disposed.
                    if (_addressFocused && _suggestions.isNotEmpty)
                      Positioned.fill(
                        child: _SuggestionPanel(
                          items: _suggestions,
                          onSelected: _applySuggestion,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: toolbarTop
            ? null
            : SafeArea(top: false, child: toolbar),
      ),
    );
  }
}

/// A thin strip on the screen edge that turns a horizontal drag into
/// back/forward navigation, so the "edge swipe" setting does something real.
class _EdgeSwipeArea extends StatelessWidget {
  const _EdgeSwipeArea({required this.alignment, required this.onSwipe});

  final Alignment alignment;
  final VoidCallback onSwipe;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (isLeft && velocity > 250) {
            onSwipe();
          } else if (!isLeft && velocity < -250) {
            onSwipe();
          }
        },
        child: const SizedBox(width: 20, height: double.infinity),
      ),
    );
  }
}

/// Friendly error state with recovery actions.
class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onGoHome,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('This page could not load',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: onGoHome, child: const Text('Go home')),
            ],
          ),
        ],
      ),
    );
  }
}


/// Address-bar suggestion panel: anchored under the bar, scrollable, with a
/// favicon or a kind icon per row.
class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({required this.items, required this.onSelected});

  final List<SuggestionItem> items;
  final ValueChanged<SuggestionItem> onSelected;

  IconData _iconFor(SuggestionKind kind) {
    switch (kind) {
      case SuggestionKind.search:
        return Icons.search_rounded;
      case SuggestionKind.history:
        return Icons.history_rounded;
      case SuggestionKind.bookmark:
        return Icons.bookmark_border_rounded;
      case SuggestionKind.frequent:
        return Icons.trending_up_rounded;
      case SuggestionKind.url:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: TvSpace.xxl),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: TvSpace.page + 44,
          endIndent: TvSpace.page,
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final hasUrl = (item.url ?? '').isNotEmpty;
          final subtitle = hasUrl
              ? UrlUtils.hostOf(item.url!)
              : 'Search with your engine';
          return InkWell(
            onTap: () => onSelected(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TvSpace.page,
                vertical: TvSpace.md,
              ),
              child: Row(
                children: [
                  if (hasUrl)
                    TvFavicon(url: item.url!, size: 28, radius: TvRadius.sm)
                  else
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(TvRadius.sm),
                      ),
                      child: Icon(
                        _iconFor(item.kind),
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: TvSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasUrl
                              ? UrlUtils.cleanTitle(item.title, item.url!)
                              : item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TvText.body.copyWith(fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TvText.caption,
                        ),
                      ],
                    ),
                  ),
                  if (hasUrl)
                    Icon(
                      Icons.north_east_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
