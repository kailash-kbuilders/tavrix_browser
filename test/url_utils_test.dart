import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/models/search_engine.dart';
import 'package:tavrix_browser/utils/url_utils.dart';

void main() {
  group('looksLikeUrl', () {
    test('detects plain domains', () {
      expect(UrlUtils.looksLikeUrl('example.com'), isTrue);
      expect(UrlUtils.looksLikeUrl('www.google.co.in/search'), isTrue);
      expect(UrlUtils.looksLikeUrl('localhost:8080'), isTrue);
    });

    test('treats words as search queries', () {
      expect(UrlUtils.looksLikeUrl('flutter tutorial'), isFalse);
      expect(UrlUtils.looksLikeUrl('hello'), isFalse);
      expect(UrlUtils.looksLikeUrl(''), isFalse);
    });

    test('accepts explicit schemes', () {
      expect(UrlUtils.looksLikeUrl('https://example.com'), isTrue);
      expect(UrlUtils.looksLikeUrl('mailto:a@b.com'), isTrue);
    });
  });

  group('normalizeUrl', () {
    test('adds https when missing', () {
      expect(UrlUtils.normalizeUrl('example.com'), 'https://example.com');
    });

    test('keeps an existing scheme', () {
      expect(UrlUtils.normalizeUrl('http://example.com'),
          'http://example.com');
    });
  });

  group('resolveInput', () {
    final engine = SearchEngine.defaults.first;

    test('builds a search URL for a query', () {
      final url = UrlUtils.resolveInput('tavrix browser', engine);
      expect(url, contains('tavrix%20browser'));
      expect(url, startsWith('https://www.google.com/search'));
    });

    test('returns a direct URL for a domain', () {
      expect(UrlUtils.resolveInput('example.com', engine),
          'https://example.com');
    });
  });

  group('displayUrl', () {
    test('strips the scheme and trailing slash', () {
      expect(UrlUtils.displayUrl('https://example.com/'), 'example.com');
      expect(UrlUtils.displayUrl('http://example.com/path'),
          'example.com/path');
    });
  });

  group('hostOf', () {
    test('returns the lower-case host', () {
      expect(UrlUtils.hostOf('https://WWW.Example.COM/a'), 'www.example.com');
      expect(UrlUtils.hostOf('not a url'), '');
    });
  });
}
