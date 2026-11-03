import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/tab_model.dart';

void main() {
  group('TabModel', () {
    test('blank tab has no url', () {
      final tab = TabModel(id: 'a');
      expect(tab.isBlank, isTrue);
      expect(tab.title, 'New tab');
      expect(tab.isPrivate, isFalse);
      expect(tab.isDesktopMode, isFalse);
    });

    test('json round trip keeps url, title and flags', () {
      final tab = TabModel(
        id: 't1',
        url: 'https://example.com',
        title: 'Example',
        isPinned: true,
        groupName: 'Work',
      );
      final restored = TabModel.fromJson(tab.toJson());
      expect(restored.id, 't1');
      expect(restored.url, 'https://example.com');
      expect(restored.title, 'Example');
      expect(restored.isPinned, isTrue);
      expect(restored.groupName, 'Work');
    });

    test('private flag is never written to the session payload', () {
      final tab = TabModel(id: 'p1', url: 'https://secret.example', isPrivate: true);
      expect(tab.toJson().containsKey('isPrivate'), isFalse);
    });
  });
}
