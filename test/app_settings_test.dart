import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/app_settings.dart';
import 'package:tavrix_browser/models/search_engine.dart';

void main() {
  group('AppSettings', () {
    test('defaults are sensible', () {
      final settings = AppSettings();
      expect(settings.themeMode, 'dark');
      expect(settings.searchEngine.id, 'google');
      expect(settings.toolbarPosition, 'bottom');
      expect(settings.javaScriptEnabled, isTrue);
      expect(settings.cookiesEnabled, isTrue);
      expect(settings.fontScale, 1.0);
    });

    test('json round trip keeps every field', () {
      final original = AppSettings()
        ..themeMode = 'dark'
        ..accentColor = 0xFF12A594
        ..searchEngineId = 'duckduckgo'
        ..toolbarPosition = 'top'
        ..homepageUrl = 'https://example.com'
        ..fontScale = 1.2
        ..haptics = false
        ..animations = false
        ..desktopMode = true
        ..swipeAddressBarSwitchesTabs = false
        ..edgeSwipeNavigation = false
        ..notifyProgress = false
        ..notifyComplete = false
        ..notifyFailed = false
        ..blockPopups = false
        ..javaScriptEnabled = false
        ..cookiesEnabled = false
        ..doNotTrack = true
        ..automaticPrivateCleanup = false
        ..translationLanguage = 'hi'
        ..compactLayout = true
        ..tabLayout = 'list'
        ..customSearchEngines = [
          const SearchEngine(
            id: 'mine',
            name: 'Mine',
            searchTemplate: 'https://search.example/?q=%s',
            isCustom: true,
          ),
        ];

      final restored = AppSettings.fromJson(original.toJson());

      expect(restored.themeMode, 'dark');
      expect(restored.accentColor, 0xFF12A594);
      expect(restored.searchEngineId, 'duckduckgo');
      expect(restored.toolbarPosition, 'top');
      expect(restored.homepageUrl, 'https://example.com');
      expect(restored.fontScale, 1.2);
      expect(restored.haptics, isFalse);
      expect(restored.animations, isFalse);
      expect(restored.desktopMode, isTrue);
      expect(restored.swipeAddressBarSwitchesTabs, isFalse);
      expect(restored.edgeSwipeNavigation, isFalse);
      expect(restored.notifyProgress, isFalse);
      expect(restored.javaScriptEnabled, isFalse);
      expect(restored.cookiesEnabled, isFalse);
      expect(restored.doNotTrack, isTrue);
      expect(restored.translationLanguage, 'hi');
      expect(restored.compactLayout, isTrue);
      expect(restored.tabLayout, 'list');
      expect(restored.customSearchEngines.single.name, 'Mine');
    });

    test('wrong types fall back instead of throwing', () {
      final restored = AppSettings.fromJson({
        'themeMode': 42,
        'fontScale': 'big',
        'haptics': 'yes',
        'accentColor': 'not-a-colour',
        'customSearchEngines': ['not a map'],
      });
      expect(restored.themeMode, 'dark');
      expect(restored.fontScale, 1.0);
      expect(restored.haptics, isFalse);
      expect(restored.accentColor, 0xFF3B6FF6);
      expect(restored.customSearchEngines, isEmpty);
    });

    test('numeric strings are parsed', () {
      final restored = AppSettings.fromJson({
        'fontScale': '1.25',
        'accentColor': '4280391411',
        'haptics': 'true',
      });
      expect(restored.fontScale, 1.25);
      expect(restored.accentColor, 4280391411);
      expect(restored.haptics, isTrue);
    });

    test('missing search engine id falls back to the first default', () {
      final settings = AppSettings()..searchEngineId = 'deleted-engine';
      expect(settings.searchEngine.id, SearchEngine.defaults.first.id);
    });

    test('custom engines are appended after the defaults', () {
      final settings = AppSettings()
        ..customSearchEngines = [
          const SearchEngine(
            id: 'x',
            name: 'X',
            searchTemplate: 'https://x/?q=%s',
            isCustom: true,
          ),
        ];
      expect(settings.allSearchEngines.length, SearchEngine.defaults.length + 1);
      expect(settings.allSearchEngines.last.id, 'x');
    });
  });
}
