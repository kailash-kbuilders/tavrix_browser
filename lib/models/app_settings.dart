import 'search_engine.dart';

/// Every user preference. Persisted as JSON in SharedPreferences.
class AppSettings {
  AppSettings({
    this.themeMode = 'system',
    this.accentColor = 0xFF3B6FF6,
    this.searchEngineId = 'google',
    this.toolbarPosition = 'bottom',
    this.homepageUrl = '',
    this.fontScale = 1.0,
    this.haptics = true,
    this.animations = true,
    this.desktopMode = false,
    this.swipeAddressBarSwitchesTabs = true,
    this.edgeSwipeNavigation = true,
    this.notifyProgress = true,
    this.notifyComplete = true,
    this.notifyFailed = true,
    this.notifyWebsite = true,
    this.blockPopups = true,
    this.javaScriptEnabled = true,
    this.cookiesEnabled = true,
    this.doNotTrack = false,
    this.automaticPrivateCleanup = true,
    this.automaticTranslation = false,
    this.translationLanguage = 'en',
    this.searchSuggestions = true,
    this.savedSearchHistory = true,
    this.compactLayout = false,
    this.tabLayout = 'grid',
    this.defaultDownloadFolder = '',
    this.customSearchEngines = const <SearchEngine>[],
  });

  String themeMode;
  int accentColor;
  String searchEngineId;
  String toolbarPosition;
  String homepageUrl;
  double fontScale;
  bool haptics;
  bool animations;
  bool desktopMode;
  bool swipeAddressBarSwitchesTabs;
  bool edgeSwipeNavigation;
  bool notifyProgress;
  bool notifyComplete;
  bool notifyFailed;
  bool notifyWebsite;
  bool blockPopups;
  bool javaScriptEnabled;
  bool cookiesEnabled;
  bool doNotTrack;
  bool automaticPrivateCleanup;
  bool automaticTranslation;
  String translationLanguage;
  bool searchSuggestions;
  bool savedSearchHistory;
  bool compactLayout;
  String tabLayout;
  String defaultDownloadFolder;
  List<SearchEngine> customSearchEngines;

  List<SearchEngine> get allSearchEngines =>
      [...SearchEngine.defaults, ...customSearchEngines];

  SearchEngine get searchEngine {
    for (final engine in allSearchEngines) {
      if (engine.id == searchEngineId) return engine;
    }
    return SearchEngine.defaults.first;
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'accentColor': accentColor,
        'searchEngineId': searchEngineId,
        'toolbarPosition': toolbarPosition,
        'homepageUrl': homepageUrl,
        'fontScale': fontScale,
        'haptics': haptics,
        'animations': animations,
        'desktopMode': desktopMode,
        'swipeAddressBarSwitchesTabs': swipeAddressBarSwitchesTabs,
        'edgeSwipeNavigation': edgeSwipeNavigation,
        'notifyProgress': notifyProgress,
        'notifyComplete': notifyComplete,
        'notifyFailed': notifyFailed,
        'notifyWebsite': notifyWebsite,
        'blockPopups': blockPopups,
        'javaScriptEnabled': javaScriptEnabled,
        'cookiesEnabled': cookiesEnabled,
        'doNotTrack': doNotTrack,
        'automaticPrivateCleanup': automaticPrivateCleanup,
        'automaticTranslation': automaticTranslation,
        'translationLanguage': translationLanguage,
        'searchSuggestions': searchSuggestions,
        'savedSearchHistory': savedSearchHistory,
        'compactLayout': compactLayout,
        'tabLayout': tabLayout,
        'defaultDownloadFolder': defaultDownloadFolder,
        'customSearchEngines':
            customSearchEngines.map((engine) => engine.toJson()).toList(),
      };

  // Parsing helpers: a settings blob written by an older version (or a
  // corrupted one) must never crash the app on launch.
  static String _string(dynamic value, String fallback) =>
      value is String ? value : fallback;

  static bool _bool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static double _double(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _int(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: _string(json['themeMode'], 'system'),
        accentColor: _int(json['accentColor'], 0xFF3B6FF6),
        searchEngineId: _string(json['searchEngineId'], 'google'),
        toolbarPosition: _string(json['toolbarPosition'], 'bottom'),
        homepageUrl: _string(json['homepageUrl'], ''),
        fontScale: _double(json['fontScale'], 1.0),
        haptics: _bool(json['haptics'], true),
        animations: _bool(json['animations'], true),
        desktopMode: _bool(json['desktopMode'], false),
        swipeAddressBarSwitchesTabs:
            _bool(json['swipeAddressBarSwitchesTabs'], true),
        edgeSwipeNavigation: _bool(json['edgeSwipeNavigation'], true),
        notifyProgress: _bool(json['notifyProgress'], true),
        notifyComplete: _bool(json['notifyComplete'], true),
        notifyFailed: _bool(json['notifyFailed'], true),
        notifyWebsite: _bool(json['notifyWebsite'], true),
        blockPopups: _bool(json['blockPopups'], true),
        javaScriptEnabled: _bool(json['javaScriptEnabled'], true),
        cookiesEnabled: _bool(json['cookiesEnabled'], true),
        doNotTrack: _bool(json['doNotTrack'], false),
        automaticPrivateCleanup: _bool(json['automaticPrivateCleanup'], true),
        automaticTranslation: _bool(json['automaticTranslation'], false),
        translationLanguage: _string(json['translationLanguage'], 'en'),
        searchSuggestions: _bool(json['searchSuggestions'], true),
        savedSearchHistory: _bool(json['savedSearchHistory'], true),
        compactLayout: _bool(json['compactLayout'], false),
        tabLayout: _string(json['tabLayout'], 'grid'),
        defaultDownloadFolder: _string(json['defaultDownloadFolder'], ''),
        customSearchEngines: (json['customSearchEngines'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SearchEngine.fromJson)
            .toList(),
      );
}
