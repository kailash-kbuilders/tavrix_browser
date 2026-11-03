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

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: json['themeMode'] as String? ?? 'system',
        accentColor: json['accentColor'] as int? ?? 0xFF3B6FF6,
        searchEngineId: json['searchEngineId'] as String? ?? 'google',
        toolbarPosition: json['toolbarPosition'] as String? ?? 'bottom',
        homepageUrl: json['homepageUrl'] as String? ?? '',
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        haptics: json['haptics'] as bool? ?? true,
        animations: json['animations'] as bool? ?? true,
        desktopMode: json['desktopMode'] as bool? ?? false,
        swipeAddressBarSwitchesTabs:
            json['swipeAddressBarSwitchesTabs'] as bool? ?? true,
        edgeSwipeNavigation: json['edgeSwipeNavigation'] as bool? ?? true,
        notifyProgress: json['notifyProgress'] as bool? ?? true,
        notifyComplete: json['notifyComplete'] as bool? ?? true,
        notifyFailed: json['notifyFailed'] as bool? ?? true,
        notifyWebsite: json['notifyWebsite'] as bool? ?? true,
        blockPopups: json['blockPopups'] as bool? ?? true,
        javaScriptEnabled: json['javaScriptEnabled'] as bool? ?? true,
        cookiesEnabled: json['cookiesEnabled'] as bool? ?? true,
        doNotTrack: json['doNotTrack'] as bool? ?? false,
        automaticPrivateCleanup: json['automaticPrivateCleanup'] as bool? ?? true,
        automaticTranslation: json['automaticTranslation'] as bool? ?? false,
        translationLanguage: json['translationLanguage'] as String? ?? 'en',
        searchSuggestions: json['searchSuggestions'] as bool? ?? true,
        savedSearchHistory: json['savedSearchHistory'] as bool? ?? true,
        compactLayout: json['compactLayout'] as bool? ?? false,
        tabLayout: json['tabLayout'] as String? ?? 'grid',
        defaultDownloadFolder: json['defaultDownloadFolder'] as String? ?? '',
        customSearchEngines: (json['customSearchEngines'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SearchEngine.fromJson)
            .toList(),
      );
}
