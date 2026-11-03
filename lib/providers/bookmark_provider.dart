import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bookmark.dart';
import '../services/database_service.dart';

/// Bookmarks with folders, favorites, search and JSON import/export.
class BookmarkProvider extends ChangeNotifier {
  BookmarkProvider(this._db);

  final DatabaseService _db;

  List<Bookmark> _bookmarks = [];
  String _query = '';
  bool _loaded = false;

  bool get isLoaded => _loaded;
  String get query => _query;

  List<Bookmark> get all => List.unmodifiable(_bookmarks);

  List<Bookmark> get visible {
    if (_query.trim().isEmpty) return all;
    final needle = _query.trim().toLowerCase();
    return _bookmarks
        .where((bookmark) =>
            bookmark.title.toLowerCase().contains(needle) ||
            bookmark.url.toLowerCase().contains(needle))
        .toList();
  }

  List<Bookmark> get favorites =>
      _bookmarks.where((bookmark) => bookmark.isFavorite).toList();

  List<String> get folders {
    final set = <String>{};
    for (final bookmark in _bookmarks) {
      final folder = bookmark.folder;
      if (folder != null && folder.trim().isNotEmpty) set.add(folder);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Bookmark> inFolder(String? folder) => _bookmarks
      .where((bookmark) => (bookmark.folder ?? '') == (folder ?? ''))
      .toList();

  Future<void> load() async {
    try {
      _bookmarks = await _db.bookmarks();
    } catch (_) {
      _bookmarks = [];
    }
    _loaded = true;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  bool isBookmarked(String url) =>
      _bookmarks.any((bookmark) => bookmark.url == url);

  Bookmark? forUrl(String url) {
    for (final bookmark in _bookmarks) {
      if (bookmark.url == url) return bookmark;
    }
    return null;
  }

  Future<void> add({
    required String title,
    required String url,
    String? folder,
    String? description,
  }) async {
    if (url.trim().isEmpty) return;
    if (isBookmarked(url)) return;
    final bookmark = Bookmark(
      title: title.trim().isEmpty ? url : title.trim(),
      url: url.trim(),
      folder: folder,
      description: description,
      position: _bookmarks.length,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      final id = await _db.insertBookmark(bookmark);
      _bookmarks = [..._bookmarks, bookmark.copyWith(id: id)];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> update(Bookmark bookmark) async {
    try {
      await _db.updateBookmark(bookmark);
      _bookmarks = _bookmarks
          .map((item) => item.id == bookmark.id ? bookmark : item)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> remove(Bookmark bookmark) async {
    if (bookmark.id == null) return;
    try {
      await _db.deleteBookmark(bookmark.id!);
      _bookmarks =
          _bookmarks.where((item) => item.id != bookmark.id).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(Bookmark bookmark) async {
    await update(bookmark.copyWith(isFavorite: !bookmark.isFavorite));
  }

  Future<void> removeAll() async {
    try {
      await _db.deleteAllBookmarks();
      _bookmarks = [];
      notifyListeners();
    } catch (_) {}
  }

  /// Exports every bookmark as JSON text through the system share sheet.
  Future<void> exportBookmarks() async {
    final payload = jsonEncode({
      'format': 'tavrix.bookmarks',
      'version': 1,
      'bookmarks': _bookmarks.map((bookmark) => bookmark.toMap()).toList(),
    });
    await Share.share(payload, subject: 'Tavrix bookmarks');
  }

  /// Imports bookmarks from JSON text the user pasted. Returns the number of
  /// bookmarks added.
  Future<int> importBookmarks(String rawJson) async {
    var added = 0;
    try {
      final decoded = jsonDecode(rawJson);
      List<dynamic> entries = [];
      if (decoded is Map && decoded['bookmarks'] is List) {
        entries = decoded['bookmarks'] as List<dynamic>;
      } else if (decoded is List) {
        entries = decoded;
      }
      for (final entry in entries) {
        if (entry is! Map) continue;
        final map = Map<String, Object?>.from(entry);
        final url = map['url'] as String? ?? '';
        if (url.isEmpty || isBookmarked(url)) continue;
        final bookmark = Bookmark(
          title: map['title'] as String? ?? url,
          url: url,
          description: map['description'] as String?,
          folder: map['folder'] as String?,
          position: _bookmarks.length + added,
          isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        final id = await _db.insertBookmark(bookmark);
        _bookmarks = [..._bookmarks, bookmark.copyWith(id: id)];
        added++;
      }
      if (added > 0) notifyListeners();
    } catch (_) {
      return added;
    }
    return added;
  }
}
