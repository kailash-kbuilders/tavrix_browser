import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tavrix_browser/models/bookmark.dart';
import 'package:tavrix_browser/models/closed_tab.dart';
import 'package:tavrix_browser/models/download_item.dart';
import 'package:tavrix_browser/models/history_entry.dart';
import 'package:tavrix_browser/models/site_permission.dart';
import 'package:tavrix_browser/services/database_service.dart';

/// These tests run the real SQLite schema through sqflite_common_ffi, so the
/// bookmark/history/download/permission queries are exercised for real.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService db;

  setUp(() async {
    db = DatabaseService();
    await db.init();
    // Start from a clean slate for each test.
    final database = db.db;
    for (final table in [
      'bookmarks',
      'history',
      'downloads',
      'site_permissions',
      'shortcuts',
      'closed_tabs',
      'offline_pages',
    ]) {
      await database.delete(table);
    }
  });

  tearDown(() async {
    await db.db.close();
  });

  test('bookmarks: insert, read, duplicate check, update and delete', () async {
    final id = await db.insertBookmark(const Bookmark(
      title: 'Example',
      url: 'https://example.com',
      folder: 'Work/Reading',
      createdAt: 1000,
    ));
    expect(id, greaterThan(0));

    var all = await db.bookmarks();
    expect(all.length, 1);
    expect(all.first.folder, 'Work/Reading');
    expect(await db.bookmarkExists('https://example.com'), isTrue);

    await db.updateBookmark(all.first.copyWith(title: 'Renamed', isFavorite: true));
    all = await db.bookmarks();
    expect(all.first.title, 'Renamed');
    expect(all.first.isFavorite, isTrue);

    await db.deleteBookmark(all.first.id!);
    expect(await db.bookmarks(), isEmpty);
  });

  test('history: newest first, search and range delete', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insertHistory(HistoryEntry(
      title: 'Old page',
      url: 'https://old.example',
      domain: 'old.example',
      visitedAt: now - const Duration(days: 3).inMilliseconds,
    ));
    await db.insertHistory(HistoryEntry(
      title: 'New page',
      url: 'https://new.example',
      domain: 'new.example',
      visitedAt: now,
    ));

    final all = await db.history();
    expect(all.length, 2);
    expect(all.first.url, 'https://new.example');

    final found = await db.history(query: 'old');
    expect(found.length, 1);
    expect(found.first.domain, 'old.example');

    expect((await db.historyDomains()).length, 2);

    await db.deleteHistoryBefore(
        now - const Duration(days: 1).inMilliseconds);
    final remaining = await db.history();
    expect(remaining.length, 1);
    expect(remaining.first.url, 'https://new.example');

    await db.clearHistory();
    expect(await db.history(), isEmpty);
  });

  test('downloads: upsert by id and clear finished records', () async {
    final running = DownloadItem(
      id: 'd1',
      url: 'https://example.com/a.zip',
      filename: 'a.zip',
      status: DownloadStatus.running,
      receivedBytes: 10,
      totalBytes: 100,
      createdAt: 1,
    );
    await db.saveDownload(running);
    await db.saveDownload(running.copyWith(receivedBytes: 60));

    var items = await db.downloads();
    expect(items.length, 1);
    expect(items.first.receivedBytes, 60);

    await db.saveDownload(DownloadItem(
      id: 'd2',
      url: 'https://example.com/b.zip',
      filename: 'b.zip',
      status: DownloadStatus.completed,
      createdAt: 2,
    ));
    await db.clearDownloadRecords();

    items = await db.downloads();
    expect(items.length, 1);
    expect(items.first.id, 'd1');
  });

  test('site permissions are unique per host and permission', () async {
    expect(await db.siteDecision('example.com', 'camera'), isNull);

    await db.setSiteDecision('example.com', 'camera', SiteDecision.block);
    expect(await db.siteDecision('example.com', 'camera'), SiteDecision.block);

    await db.setSiteDecision('example.com', 'camera', SiteDecision.allow);
    final stored = await db.sitePermissions();
    expect(stored.length, 1);
    expect(stored.first.decision, SiteDecision.allow);

    await db.deleteSitePermissions('example.com');
    expect(await db.siteDecision('example.com', 'camera'), isNull);
  });

  test('closed tabs are capped so the table cannot grow forever', () async {
    for (var i = 0; i < 60; i++) {
      await db.insertClosedTab(ClosedTab(
        title: 'Tab $i',
        url: 'https://example.com/$i',
        closedAt: 1000 + i,
      ));
    }
    final tabs = await db.closedTabs(limit: 100);
    expect(tabs.length, lessThanOrEqualTo(50));
    expect(tabs.first.url, 'https://example.com/59');
  });
}
