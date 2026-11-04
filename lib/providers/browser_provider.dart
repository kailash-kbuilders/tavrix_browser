import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/closed_tab.dart';
import '../models/history_entry.dart';
import '../models/tab_model.dart';
import '../services/browser_engine.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/url_utils.dart';
import 'settings_provider.dart';

/// Owns the open tabs and their live WebView state.
class BrowserProvider extends ChangeNotifier {
  BrowserProvider({required DatabaseService db, required SettingsProvider settings})
      : _db = db,
        _settings = settings;

  final DatabaseService _db;
  final SettingsProvider _settings;
  final Uuid _uuid = const Uuid();

  final List<TabModel> _tabs = [];
  String? _activeTabId;
  List<ClosedTab> _recentlyClosed = [];
  Timer? _persistTimer;
  bool _restored = false;

  List<TabModel> get tabs => List.unmodifiable(_tabs);
  List<TabModel> get regularTabs => _tabs.where((tab) => !tab.isPrivate).toList();
  List<TabModel> get privateTabs => _tabs.where((tab) => tab.isPrivate).toList();
  List<ClosedTab> get recentlyClosed => List.unmodifiable(_recentlyClosed);
  String? get activeTabId => _activeTabId;

  TabModel? get activeTab {
    for (final tab in _tabs) {
      if (tab.id == _activeTabId) return tab;
    }
    return _tabs.isEmpty ? null : _tabs.first;
  }

  bool get isPrivateActive => activeTab?.isPrivate ?? false;

  // ------------------------------------------------------------- lifecycle

  Future<void> restoreSession() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(TavrixConstants.sessionKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          final savedTabs = (data['tabs'] as List<dynamic>? ?? []);
          for (final entry in savedTabs) {
            if (entry is Map) {
              final tab = TabModel.fromJson(Map<String, dynamic>.from(entry));
              _tabs.add(tab);
            }
          }
          final savedActive = data['activeId'] as String?;
          if (savedActive != null &&
              _tabs.any((tab) => tab.id == savedActive)) {
            _activeTabId = savedActive;
          }
        }
      } catch (_) {
        // Corrupt session: start clean instead of crashing.
      }
    }
    if (_tabs.isEmpty) {
      _tabs.add(TabModel(id: _uuid.v4()));
    }
    _activeTabId ??= _tabs.first.id;
    await _loadClosedTabs();
    notifyListeners();
  }

  Future<void> _loadClosedTabs() async {
    try {
      _recentlyClosed = await _db.closedTabs();
      notifyListeners();
    } catch (_) {
      _recentlyClosed = [];
    }
  }

  Future<void> refreshRecentlyClosed() => _loadClosedTabs();

  // ----------------------------------------------------------------- tabs

  TabModel openTab({String url = '', bool isPrivate = false, bool switchTo = true}) {
    final tab = TabModel(
      id: _uuid.v4(),
      url: url,
      isPrivate: isPrivate,
      isDesktopMode: _settings.settings.desktopMode,
    );
    _tabs.add(tab);
    if (switchTo) _activeTabId = tab.id;
    _schedulePersist();
    notifyListeners();
    return tab;
  }

  void activateTab(String id) {
    if (!_tabs.any((tab) => tab.id == id)) return;
    _activeTabId = id;
    _schedulePersist();
    notifyListeners();
  }

  Future<void> closeTab(String id) async {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return;
    final tab = _tabs[index];
    if (!tab.isPrivate && tab.url.isNotEmpty) {
      try {
        await _db.insertClosedTab(ClosedTab(
          title: UrlUtils.cleanTitle(tab.title, tab.url),
          url: tab.url,
          closedAt: DateTime.now().millisecondsSinceEpoch,
        ));
        _recentlyClosed = await _db.closedTabs();
      } catch (_) {}
    }
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      final replacement = TabModel(id: _uuid.v4());
      _tabs.add(replacement);
      _activeTabId = replacement.id;
    } else if (_activeTabId == id) {
      final newIndex = index.clamp(0, _tabs.length - 1);
      _activeTabId = _tabs[newIndex].id;
    }
    _schedulePersist();
    notifyListeners();
  }

  void duplicateTab(String id) {
    final tab = _tabById(id);
    if (tab == null) return;
    openTab(url: tab.url, isPrivate: tab.isPrivate);
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tabs.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0 || target >= _tabs.length) return;
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(target, tab);
    _schedulePersist();
    notifyListeners();
  }

  Future<void> closeAllTabs({bool includePrivate = false}) async {
    final keep = _tabs
        .where((tab) => !includePrivate && tab.isPrivate)
        .toList(growable: false);
    for (final tab in _tabs) {
      if (!tab.isPrivate || includePrivate) {
        if (!tab.isPrivate && tab.url.isNotEmpty) {
          try {
            await _db.insertClosedTab(ClosedTab(
              title: UrlUtils.cleanTitle(tab.title, tab.url),
              url: tab.url,
              closedAt: DateTime.now().millisecondsSinceEpoch,
            ));
          } catch (_) {}
        }
      }
    }
    _tabs
      ..clear()
      ..addAll(keep);
    if (_tabs.isEmpty) {
      _tabs.add(TabModel(id: _uuid.v4()));
    }
    _activeTabId = _tabs.first.id;
    _recentlyClosed = await _db.closedTabs();
    _schedulePersist();
    notifyListeners();
  }

  Future<void> closeAllPrivateTabs() async {
    _tabs.removeWhere((tab) => tab.isPrivate);
    if (_tabs.isEmpty) {
      _tabs.add(TabModel(id: _uuid.v4()));
    }
    if (!_tabs.any((tab) => tab.id == _activeTabId)) {
      _activeTabId = _tabs.first.id;
    }
    _schedulePersist();
    notifyListeners();
  }

  Future<void> restoreClosedTab(ClosedTab closed) async {
    if (closed.id != null) {
      try {
        await _db.deleteClosedTab(closed.id!);
        _recentlyClosed = await _db.closedTabs();
      } catch (_) {}
    }
    openTab(url: closed.url);
  }

  Future<void> setTabGroup(String id, String? groupName) async {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.groupName = (groupName == null || groupName.trim().isEmpty)
        ? null
        : groupName.trim();
    _schedulePersist();
    notifyListeners();
  }

  void togglePin(String id) {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.isPinned = !tab.isPinned;
    _schedulePersist();
    notifyListeners();
  }

  void switchToNextTab() {
    if (_tabs.length < 2) return;
    final index = _tabs.indexWhere((tab) => tab.id == _activeTabId);
    final next = (index + 1) % _tabs.length;
    _activeTabId = _tabs[next].id;
    notifyListeners();
  }

  void switchToPreviousTab() {
    if (_tabs.length < 2) return;
    final index = _tabs.indexWhere((tab) => tab.id == _activeTabId);
    final previous = (index - 1 + _tabs.length) % _tabs.length;
    _activeTabId = _tabs[previous].id;
    notifyListeners();
  }

  TabModel? _tabById(String id) {
    for (final tab in _tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }

  // ---------------------------------------------------- webview state updates

  void attachController(String id, InAppWebViewController controller) {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.controller = controller;
  }

  void onLoadStart(String id, String? url) {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.isLoading = true;
    tab.errorMessage = null;
    if (url != null && !UrlUtils.isBlank(url)) {
      tab.url = url;
      tab.isSecure = UrlUtils.isSecure(url);
    }
    notifyListeners();
  }

  Future<void> onLoadStop(String id, String? url) async {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.isLoading = false;
    tab.progress = 1;
    if (url != null && !UrlUtils.isBlank(url)) {
      tab.url = url;
      tab.isSecure = UrlUtils.isSecure(url);
    }
    notifyListeners();
    await _recordHistory(tab);
    _schedulePersist();
  }

  void onProgressChanged(String id, int progress) {
    final tab = _tabById(id);
    if (tab == null) return;
    final next = progress / 100.0;
    if ((next - tab.progress).abs() < 0.04 && progress != 100) return;
    tab.progress = next;
    tab.isLoading = progress < 100;
    notifyListeners();
  }

  void onTitleChanged(String id, String? title) {
    final tab = _tabById(id);
    if (tab == null) return;
    if (title != null && title.trim().isNotEmpty) {
      tab.title = title.trim();
      notifyListeners();
    }
  }

  void onUrlChanged(String id, String? url) {
    final tab = _tabById(id);
    if (tab == null) return;
    if (url == null || UrlUtils.isBlank(url)) return;
    if (tab.url == url) return;
    tab.url = url;
    tab.isSecure = UrlUtils.isSecure(url);
    notifyListeners();
    _schedulePersist();
  }

  void onHistoryStateChanged(String id, {bool? canGoBack, bool? canGoForward}) {
    final tab = _tabById(id);
    if (tab == null) return;
    var changed = false;
    if (canGoBack != null && tab.canGoBack != canGoBack) {
      tab.canGoBack = canGoBack;
      changed = true;
    }
    if (canGoForward != null && tab.canGoForward != canGoForward) {
      tab.canGoForward = canGoForward;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void onError(String id, String message) {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.isLoading = false;
    tab.errorMessage = message;
    notifyListeners();
  }

  void clearError(String id) {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.errorMessage = null;
    notifyListeners();
  }

  Future<void> _recordHistory(TabModel tab) async {
    if (tab.isPrivate) return;
    final url = tab.url;
    if (url.isEmpty || UrlUtils.isBlank(url)) return;
    if (!url.startsWith('http')) return;
    try {
      await _db.insertHistory(HistoryEntry(
        title: tab.title,
        url: url,
        domain: UrlUtils.hostOf(url),
        visitedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    } catch (_) {
      // History failures must never break browsing.
    }
  }

  // ------------------------------------------------------------ navigation

  Future<void> goBack(String id) async {
    final controller = _tabById(id)?.controller;
    if (controller == null) return;
    try {
      await controller.goBack();
    } catch (_) {}
  }

  Future<void> goForward(String id) async {
    final controller = _tabById(id)?.controller;
    if (controller == null) return;
    try {
      await controller.goForward();
    } catch (_) {}
  }

  Future<void> reload(String id) async {
    final controller = _tabById(id)?.controller;
    if (controller == null) return;
    try {
      await controller.reload();
    } catch (_) {}
  }

  Future<void> stopLoading(String id) async {
    final controller = _tabById(id)?.controller;
    if (controller == null) return;
    try {
      await controller.stopLoading();
    } catch (_) {}
  }

  /// Shows the Tavrix home screen for this tab.
  void goHome(String id) {
    final tab = _tabById(id);
    if (tab == null) return;
    final homepage = _settings.settings.homepageUrl.trim();
    if (homepage.isNotEmpty) {
      navigate(id, homepage);
      return;
    }
    tab.url = '';
    tab.title = 'New tab';
    tab.isLoading = false;
    tab.progress = 0;
    tab.canGoBack = false;
    tab.canGoForward = false;
    tab.errorMessage = null;
    _schedulePersist();
    notifyListeners();
  }

  Future<void> navigate(String id, String url) async {
    final tab = _tabById(id);
    if (tab == null || url.isEmpty) return;
    tab.url = url;
    tab.isSecure = UrlUtils.isSecure(url);
    tab.errorMessage = null;
    notifyListeners();
    _schedulePersist();
    final controller = tab.controller;
    if (controller == null) return;
    try {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    } catch (_) {
      onError(id, 'Could not open this page.');
    }
  }

  /// Desktop mode is applied to the live WebView (user agent + viewport), then
  /// the page is reloaded once so the site serves its desktop layout. The tab
  /// keeps its URL and back/forward history.
  Future<void> toggleDesktopMode(String id) async {
    final tab = _tabById(id);
    if (tab == null) return;
    tab.isDesktopMode = !tab.isDesktopMode;
    notifyListeners();
    final controller = tab.controller;
    if (controller == null) return;
    try {
      await controller.setSettings(
        settings: BrowserEngine.settingsFor(
          appSettings: _settings.settings,
          isPrivate: tab.isPrivate,
          desktopMode: tab.isDesktopMode,
        ),
      );
    } catch (_) {}
    try {
      await controller.reload();
    } catch (_) {}
  }

  // -------------------------------------------------------------- session

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 600), persistSession);
  }

  Future<void> persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'tabs': regularTabs
            .where((tab) => tab.url.isNotEmpty)
            .map((tab) => tab.toJson())
            .toList(),
        'activeId': _activeTabId,
      };
      await prefs.setString(TavrixConstants.sessionKey, jsonEncode(payload));
    } catch (_) {
      // Losing the session file must not interrupt browsing.
    }
  }

  /// Called when the app goes to the background: private tabs are wiped when
  /// the user asked for automatic cleanup.
  Future<void> handleAppPaused() async {
    await persistSession();
    if (_settings.settings.automaticPrivateCleanup && privateTabs.isNotEmpty) {
      await closeAllPrivateTabs();
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}
