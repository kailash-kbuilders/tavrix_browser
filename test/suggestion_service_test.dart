import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/services/suggestion_service.dart';

void main() {
  group('SuggestionService.parsePayload', () {
    test('reads the Google firefox-client shape', () {
      final payload = [
        'flut',
        ['flutter', 'flutter tutorial', 'flutterwave'],
      ];
      expect(SuggestionService.parsePayload(payload),
          ['flutter', 'flutter tutorial', 'flutterwave']);
    });

    test('reads the Bing osjson and DuckDuckGo ac shapes', () {
      expect(
        SuggestionService.parsePayload(['tavrix', ['tavrix browser']]),
        ['tavrix browser'],
      );
    });

    test('respects the limit', () {
      final payload = [
        'q',
        ['a', 'b', 'c', 'd', 'e'],
      ];
      expect(SuggestionService.parsePayload(payload, limit: 2), ['a', 'b']);
    });

    test('ignores malformed payloads instead of throwing', () {
      expect(SuggestionService.parsePayload(null), isEmpty);
      expect(SuggestionService.parsePayload('nonsense'), isEmpty);
      expect(SuggestionService.parsePayload([1, 2, 3]), isEmpty);
      expect(SuggestionService.parsePayload(['q', 'not a list']), isEmpty);
      expect(SuggestionService.parsePayload(['q', [1, null, 'ok']]), ['ok']);
    });
  });

  group('SuggestionService.merge', () {
    test('keeps local matches first and de-duplicates', () {
      final merged = SuggestionService.merge(
        ['flutter', 'Flutter apps'],
        ['flutter apps', 'flutterwave'],
      );
      expect(merged, ['flutter', 'Flutter apps', 'flutterwave']);
    });

    test('caps the list and drops blanks', () {
      final merged = SuggestionService.merge(
        ['', '  '],
        ['a', 'b', 'c'],
        limit: 2,
      );
      expect(merged, ['a', 'b']);
    });
  });
}
