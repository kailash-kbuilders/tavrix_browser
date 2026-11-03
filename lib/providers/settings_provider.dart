import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/search_engine.dart';
import '../services/settings_service.dart';

/// Holds [AppSettings] and persists every change.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService();

  final SettingsService _service;
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _settings = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _commit() async {
    notifyListeners();
    await _service.save(_settings);
  }

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  SearchEngine get searchEngine => _settings.searchEngine;
  List<SearchEngine> get searchEngines => _settings.allSearchEngines;

  Future<void> setThemeMode(String mode) async {
    _settings.themeMode = mode;
    await _commit();
  }

  Future<void> setAccentColor(int color) async {
    _settings.accentColor = color;
    await _commit();
  }

  Future<void> setSearchEngine(String id) async {
    _settings.searchEngineId = id;
    await _commit();
  }

  Future<void> setToolbarPosition(String position) async {
    _settings.toolbarPosition = position;
    await _commit();
  }

  Future<void> setHomepage(String url) async {
    _settings.homepageUrl = url;
    await _commit();
  }

  Future<void> setFontScale(double scale) async {
    _settings.fontScale = scale;
    await _commit();
  }

  Future<void> setHaptics(bool enabled) async {
    _settings.haptics = enabled;
    await _commit();
  }

  Future<void> setAnimations(bool enabled) async {
    _settings.animations = enabled;
    await _commit();
  }

  Future<void> setDesktopMode(bool enabled) async {
    _settings.desktopMode = enabled;
    await _commit();
  }

  Future<void> setSwipeAddressBarSwitchesTabs(bool enabled) async {
    _settings.swipeAddressBarSwitchesTabs = enabled;
    await _commit();
  }

  Future<void> setEdgeSwipeNavigation(bool enabled) async {
    _settings.edgeSwipeNavigation = enabled;
    await _commit();
  }

  Future<void> setNotifyProgress(bool enabled) async {
    _settings.notifyProgress = enabled;
    await _commit();
  }

  Future<void> setNotifyComplete(bool enabled) async {
    _settings.notifyComplete = enabled;
    await _commit();
  }

  Future<void> setNotifyFailed(bool enabled) async {
    _settings.notifyFailed = enabled;
    await _commit();
  }

  Future<void> setNotifyWebsite(bool enabled) async {
    _settings.notifyWebsite = enabled;
    await _commit();
  }

  Future<void> setBlockPopups(bool enabled) async {
    _settings.blockPopups = enabled;
    await _commit();
  }

  Future<void> setJavaScriptEnabled(bool enabled) async {
    _settings.javaScriptEnabled = enabled;
    await _commit();
  }

  Future<void> setCookiesEnabled(bool enabled) async {
    _settings.cookiesEnabled = enabled;
    await _commit();
  }

  Future<void> setDoNotTrack(bool enabled) async {
    _settings.doNotTrack = enabled;
    await _commit();
  }

  Future<void> setAutomaticPrivateCleanup(bool enabled) async {
    _settings.automaticPrivateCleanup = enabled;
    await _commit();
  }

  Future<void> setAutomaticTranslation(bool enabled) async {
    _settings.automaticTranslation = enabled;
    await _commit();
  }

  Future<void> setTranslationLanguage(String code) async {
    _settings.translationLanguage = code;
    await _commit();
  }

  Future<void> setSearchSuggestions(bool enabled) async {
    _settings.searchSuggestions = enabled;
    await _commit();
  }

  Future<void> setSavedSearchHistory(bool enabled) async {
    _settings.savedSearchHistory = enabled;
    await _commit();
  }

  Future<void> setCompactLayout(bool enabled) async {
    _settings.compactLayout = enabled;
    await _commit();
  }

  Future<void> setTabLayout(String layout) async {
    _settings.tabLayout = layout;
    await _commit();
  }

  Future<void> addSearchEngine(SearchEngine engine) async {
    _settings.customSearchEngines = [..._settings.customSearchEngines, engine];
    await _commit();
  }

  Future<void> updateSearchEngine(SearchEngine engine) async {
    _settings.customSearchEngines = _settings.customSearchEngines
        .map((item) => item.id == engine.id ? engine : item)
        .toList();
    await _commit();
  }

  Future<void> removeSearchEngine(String id) async {
    _settings.customSearchEngines = _settings.customSearchEngines
        .where((engine) => engine.id != id)
        .toList();
    if (_settings.searchEngineId == id) {
      _settings.searchEngineId = SearchEngine.defaults.first.id;
    }
    await _commit();
  }
}
