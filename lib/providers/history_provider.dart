import 'package:flutter/foundation.dart';

import '../models/history_entry.dart';
import '../services/database_service.dart';

/// Browsing history with search and range deletion.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._db);

  final DatabaseService _db;

  List<HistoryEntry> _entries = [];
  List<String> _domains = [];
  String _query = '';
  bool _isLoading = false;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  List<String> get domains => List.unmodifiable(_domains);
  String get query => _query;
  bool get isLoading => _isLoading;

  /// History grouped by day, newest first.
  Map<String, List<HistoryEntry>> get grouped {
    final map = <String, List<HistoryEntry>>{};
    for (final entry in _entries) {
      final date = entry.visitedDate;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }

  Future<void> load({String query = ''}) async {
    _query = query;
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _db.history(query: query);
      _domains = await _db.historyDomains();
    } catch (_) {
      _entries = [];
      _domains = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) => load(query: query);

  Future<void> removeEntry(HistoryEntry entry) async {
    if (entry.id == null) return;
    try {
      await _db.deleteHistoryEntry(entry.id!);
      _entries = _entries.where((item) => item.id != entry.id).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeEntries(List<HistoryEntry> entries) async {
    final ids = entries
        .map((entry) => entry.id)
        .whereType<int>()
        .toList(growable: false);
    if (ids.isEmpty) return;
    try {
      await _db.deleteHistoryEntries(ids);
      _entries =
          _entries.where((item) => !ids.contains(item.id)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearRange({required Duration range}) async {
    final cutoff =
        DateTime.now().subtract(range).millisecondsSinceEpoch;
    try {
      await _db.deleteHistoryBefore(cutoff);
      await load(query: _query);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _db.clearHistory();
      _entries = [];
      _domains = [];
      notifyListeners();
    } catch (_) {}
  }
}
