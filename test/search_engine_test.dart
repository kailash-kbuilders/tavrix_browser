import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/search_engine.dart';

void main() {
  test('default engines are available', () {
    expect(SearchEngine.defaults.length, greaterThanOrEqualTo(6));
    expect(SearchEngine.defaults.first.id, 'google');
  });

  test('urlFor encodes the query', () {
    const engine = SearchEngine(
      id: 'test',
      name: 'Test',
      searchTemplate: 'https://example.com/?q=%s',
    );
    expect(engine.urlFor('a b'), 'https://example.com/?q=a%20b');
  });

  test('json round trip keeps the template', () {
    const engine = SearchEngine(
      id: 'custom',
      name: 'Custom',
      searchTemplate: 'https://search.example/?q=%s',
      isCustom: true,
    );
    final restored = SearchEngine.fromJson(engine.toJson());
    expect(restored.searchTemplate, engine.searchTemplate);
    expect(restored.isCustom, isTrue);
  });
}
