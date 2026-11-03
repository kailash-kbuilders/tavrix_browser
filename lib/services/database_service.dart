import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/bookmark.dart';
import '../models/closed_tab.dart';
import '../models/download_item.dart';
import '../models/history_entry.dart';
import '../models/offline_page.dart';
import '../models/shortcut_item.dart';
import '../models/site_permission.dart';

/// SQLite storage for everything that must survive a restart: bookmarks,
/// history, downloads, shortcuts, closed tabs, site permissions and offline
/// pages.
class DatabaseService {
  Database? _db;

  static const int _schemaVersion = 1;

  Future<void> init() async {
    if (_db != null) return;
    final directory = await getDatabasesPath();
    _db = await openDatabase(
      p.join(directory, 'tavrix.db'),
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            description TEXT,
            folder TEXT,
            position INTEGER NOT NULL DEFAULT 0,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT NOT NULL,
            domain TEXT,
            visitedAt INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_history_visited ON history (visitedAt DESC)');
        await db.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            filename TEXT NOT NULL,
            path TEXT,
            mimeType TEXT,
            userAgent TEXT,
            totalBytes INTEGER NOT NULL DEFAULT 0,
            receivedBytes INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            error TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE site_permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            host TEXT NOT NULL,
            permission TEXT NOT NULL,
            decision TEXT NOT NULL,
            UNIQUE (host, permission)
          )
        ''');
        await db.execute('''
          CREATE TABLE shortcuts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            position INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE closed_tabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT NOT NULL,
            closedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_pages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT NOT NULL UNIQUE,
            filePath TEXT NOT NULL,
            savedAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Future schema changes go here, one migration block per version step.
        // Example: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
      },
    );
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('DatabaseService.init() must run before any query.');
    }
    return database;
  }

  // ----------------------------------------------------------------- bookmarks

  Future<List<Bookmark>> bookmarks() async {
    final rows = await db.query('bookmarks', orderBy: 'position ASC, title ASC');
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<int> insertBookmark(Bookmark bookmark) async {
    final map = bookmark.toMap()..remove('id');
    return db.insert('bookmarks', map);
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    if (bookmark.id == null) return;
    await db.update('bookmarks', bookmark.toMap(),
        where: 'id = ?', whereArgs: [bookmark.id]);
  }

  Future<void> deleteBookmark(int id) async {
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllBookmarks() async {
    await db.delete('bookmarks');
  }

  Future<bool> bookmarkExists(String url) async {
    final rows =
        await db.query('bookmarks', where: 'url = ?', whereArgs: [url], limit: 1);
    return rows.isNotEmpty;
  }

  // ------------------------------------------------------------------ history

  Future<List<HistoryEntry>> history({int limit = 500, String query = ''}) async {
    if (query.trim().isEmpty) {
      final rows = await db.query('history',
          orderBy: 'visitedAt DESC', limit: limit);
      return rows.map(HistoryEntry.fromMap).toList();
    }
    final like = '%${query.trim()}%';
    final rows = await db.query(
      'history',
      where: 'url LIKE ? OR title LIKE ? OR domain LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'visitedAt DESC',
      limit: limit,
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<int> insertHistory(HistoryEntry entry) async {
    final map = entry.toMap()..remove('id');
    return db.insert('history', map);
  }

  Future<void> deleteHistoryEntry(int id) async {
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHistoryEntries(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.delete('history',
        where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> deleteHistoryBefore(int timestamp) async {
    await db.delete('history',
        where: 'visitedAt < ?', whereArgs: [timestamp]);
  }

  Future<void> clearHistory() async {
    await db.delete('history');
  }

  Future<List<String>> historyDomains() async {
    final rows = await db.rawQuery(
        "SELECT DISTINCT domain FROM history "
        "WHERE domain IS NOT NULL AND domain != '' ORDER BY domain ASC");
    return rows.map((row) => row['domain'] as String? ?? '').toList();
  }

  Future<List<HistoryEntry>> mostVisited({int limit = 8}) async {
    final rows = await db.rawQuery(
      'SELECT url, title, domain, MAX(visitedAt) AS visitedAt, COUNT(*) AS hits '
      'FROM history GROUP BY url ORDER BY hits DESC, visitedAt DESC LIMIT ?',
      [limit],
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  // ---------------------------------------------------------------- downloads

  Future<List<DownloadItem>> downloads() async {
    final rows = await db.query('downloads', orderBy: 'createdAt DESC');
    return rows.map(DownloadItem.fromMap).toList();
  }

  Future<void> saveDownload(DownloadItem item) async {
    await db.insert('downloads', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDownload(String id) async {
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDownloadRecords() async {
    await db.delete('downloads',
        where: 'status IN (?, ?, ?, ?)',
        whereArgs: [
          DownloadStatus.completed.name,
          DownloadStatus.failed.name,
          DownloadStatus.cancelled.name,
          DownloadStatus.paused.name,
        ]);
  }

  // --------------------------------------------------------- site permissions

  Future<SiteDecision?> siteDecision(String host, String permission) async {
    final rows = await db.query(
      'site_permissions',
      where: 'host = ? AND permission = ?',
      whereArgs: [host, permission],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SitePermission.fromMap(rows.first).decision;
  }

  Future<void> setSiteDecision(
      String host, String permission, SiteDecision decision) async {
    await db.insert(
      'site_permissions',
      {
        'host': host,
        'permission': permission,
        'decision': decision.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SitePermission>> sitePermissions() async {
    final rows = await db.query('site_permissions',
        orderBy: 'host ASC, permission ASC');
    return rows.map(SitePermission.fromMap).toList();
  }

  Future<void> deleteSitePermissions(String host) async {
    await db.delete('site_permissions', where: 'host = ?', whereArgs: [host]);
  }

  Future<void> clearSitePermissions() async {
    await db.delete('site_permissions');
  }

  // ---------------------------------------------------------------- shortcuts

  Future<List<ShortcutItem>> shortcuts() async {
    final rows = await db.query('shortcuts', orderBy: 'position ASC, id ASC');
    return rows.map(ShortcutItem.fromMap).toList();
  }

  Future<int> insertShortcut(ShortcutItem item) async {
    final map = item.toMap()..remove('id');
    return db.insert('shortcuts', map);
  }

  Future<void> updateShortcut(ShortcutItem item) async {
    if (item.id == null) return;
    await db.update('shortcuts', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteShortcut(int id) async {
    await db.delete('shortcuts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderShortcuts(List<ShortcutItem> items) async {
    final batch = db.batch();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.id == null) continue;
      batch.update('shortcuts', {'position': i},
          where: 'id = ?', whereArgs: [item.id]);
    }
    await batch.commit(noResult: true);
  }

  // ------------------------------------------------------------- closed tabs

  Future<List<ClosedTab>> closedTabs({int limit = 20}) async {
    final rows = await db.query('closed_tabs',
        orderBy: 'closedAt DESC', limit: limit);
    return rows.map(ClosedTab.fromMap).toList();
  }

  Future<int> insertClosedTab(ClosedTab tab) async {
    final map = tab.toMap()..remove('id');
    final id = await db.insert('closed_tabs', map);
    // Keep the list bounded so the table never grows forever.
    await db.rawDelete(
      'DELETE FROM closed_tabs WHERE id NOT IN '
      '(SELECT id FROM closed_tabs ORDER BY closedAt DESC LIMIT 50)',
    );
    return id;
  }

  Future<void> deleteClosedTab(int id) async {
    await db.delete('closed_tabs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearClosedTabs() async {
    await db.delete('closed_tabs');
  }

  // ------------------------------------------------------------ offline pages

  Future<List<OfflinePage>> offlinePages() async {
    final rows = await db.query('offline_pages', orderBy: 'savedAt DESC');
    return rows.map(OfflinePage.fromMap).toList();
  }

  Future<void> saveOfflinePage(OfflinePage page) async {
    final map = page.toMap()..remove('id');
    await db.insert('offline_pages', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteOfflinePage(int id) async {
    await db.delete('offline_pages', where: 'id = ?', whereArgs: [id]);
  }
}
