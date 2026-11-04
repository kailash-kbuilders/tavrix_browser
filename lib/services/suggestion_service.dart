import 'package:dio/dio.dart';

import '../models/search_engine.dart';

/// Fetches autocomplete suggestions from the active search engine and merges
/// them with what is already stored on the device.
class SuggestionService {
  SuggestionService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Engines answer with `["query", ["suggestion", ...]]` (Google's firefox
  /// client, Bing osjson and DuckDuckGo's `ac?type=list` all match).
  static List<String> parsePayload(dynamic payload, {int limit = 6}) {
    final suggestions = <String>[];
    if (payload is List && payload.length >= 2) {
      final raw = payload[1];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is String && entry.trim().isNotEmpty) {
            suggestions.add(entry.trim());
          }
          if (suggestions.length >= limit) break;
        }
      }
    }
    return suggestions;
  }

  Future<List<String>> remote(SearchEngine engine, String query,
      {int limit = 6}) async {
    final url = engine.suggestUrlFor(query);
    if (url == null || url.isEmpty) return const [];
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
          headers: {'Accept': 'application/json'},
        ),
      );
      return parsePayload(response.data, limit: limit);
    } catch (_) {
      // Suggestions are a nicety: a failed request must never surface an error.
      return const [];
    }
  }

  /// Local matches first (they are what the user is most likely to want),
  /// then remote suggestions, de-duplicated case-insensitively.
  static List<String> merge(
    List<String> local,
    List<String> remote, {
    int limit = 8,
  }) {
    final merged = <String>[];
    for (final item in [...local, ...remote]) {
      final text = item.trim();
      if (text.isEmpty) continue;
      if (merged.any((existing) => existing.toLowerCase() == text.toLowerCase())) {
        continue;
      }
      merged.add(text);
      if (merged.length >= limit) break;
    }
    return merged;
  }

  void close() {
    _dio.close(force: true);
  }
}
