import '../models/search_engine.dart';

/// URL parsing and formatting helpers shared by the address bar and services.
class UrlUtils {
  UrlUtils._();

  static final RegExp _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:');
  static final RegExp _hostPattern = RegExp(r'^[a-zA-Z0-9\-._~%]+$');

  /// True when the text the user typed should be treated as a URL rather than
  /// a search query.
  static bool looksLikeUrl(String input) {
    final text = input.trim();
    if (text.isEmpty) return false;
    if (_schemePattern.hasMatch(text)) return true;
    if (text.contains(' ')) return false;

    final hostPart = text.split('/').first.split('?').first;
    final host = hostPart.split(':').first;
    if (host.isEmpty) return false;
    if (host == 'localhost') return true;
    if (!host.contains('.')) return false;
    if (!_hostPattern.hasMatch(host)) return false;
    return !host.endsWith('.');
  }

  /// Turns typed text into a loadable URL. Adds https:// when the scheme is
  /// missing.
  static String normalizeUrl(String input) {
    final text = input.trim();
    if (text.isEmpty) return text;
    if (_schemePattern.hasMatch(text)) return text;
    return 'https://$text';
  }

  /// Builds either a direct URL or a search URL for the given input.
  static String resolveInput(String input, SearchEngine engine) {
    final text = input.trim();
    if (text.isEmpty) return '';
    if (looksLikeUrl(text)) return normalizeUrl(text);
    return engine.urlFor(text);
  }

  static String hostOf(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      return host.isEmpty ? '' : host.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  static bool isSecure(String url) => url.toLowerCase().startsWith('https://');

  static bool isBlank(String url) =>
      url.isEmpty || url == 'about:blank' || url == 'about:newtab';

  /// Short, human-friendly form of a URL for the address bar.
  static String displayUrl(String url) {
    if (url.isEmpty) return '';
    var text = url;
    if (text.startsWith('https://')) {
      text = text.substring(8);
    } else if (text.startsWith('http://')) {
      text = text.substring(7);
    }
    if (text.endsWith('/') && text.length > 1) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// Never show an engine placeholder like "about:blank" where a real title or
  /// domain exists.
  static String cleanTitle(String title, String url) {
    final text = title.trim();
    final lowered = text.toLowerCase();
    final junk = text.isEmpty ||
        lowered == 'about:blank' ||
        lowered == 'about:newtab' ||
        lowered == 'new tab' ||
        lowered == 'untitled' ||
        text == url;
    if (!junk) return text;
    final host = hostOf(url).replaceFirst('www.', '');
    if (host.isNotEmpty) return host;
    return url.isEmpty ? 'New tab' : url;
  }

  /// "example.com" -> "example" for shortcut naming.
  static String suggestTitle(String url) {
    final host = hostOf(url);
    if (host.isEmpty) return url;
    final parts = host.replaceFirst('www.', '').split('.');
    if (parts.isEmpty) return host;
    final name = parts.first;
    if (name.isEmpty) return host;
    return name[0].toUpperCase() + name.substring(1);
  }
}
