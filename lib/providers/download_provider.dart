import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/download_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

/// Real downloads: streams bytes to disk, reports true progress, supports
/// pause (cancel + keep partial file), resume (HTTP Range), retry and delete.
class DownloadProvider extends ChangeNotifier {
  DownloadProvider({
    required DatabaseService db,
    required SettingsProvider settings,
    required NotificationService notifications,
  })  : _db = db,
        _settings = settings,
        _notifications = notifications;

  final DatabaseService _db;
  final SettingsProvider _settings;
  final NotificationService _notifications;
  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();

  final Map<String, CancelToken> _tokens = {};
  final Map<String, bool> _pausing = {};
  final Map<String, DateTime> _lastTick = {};

  List<DownloadItem> _items = [];
  bool _loaded = false;

  List<DownloadItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;

  List<DownloadItem> get active => _items
      .where((item) =>
          item.status == DownloadStatus.running ||
          item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.paused)
      .toList();

  List<DownloadItem> get finished => _items
      .where((item) =>
          item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.cancelled)
      .toList();

  Future<void> load() async {
    try {
      _items = await _db.downloads();
    } catch (_) {
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  // --------------------------------------------------------------- starting

  Future<void> startDownload({
    required String url,
    required String filename,
    String? mimeType,
    String? userAgent,
  }) async {
    if (url.trim().isEmpty) return;
    final directory = await _downloadDirectory();
    final safeName = await _uniqueFilename(directory, filename);
    final item = DownloadItem(
      id: _uuid.v4(),
      url: url,
      filename: safeName,
      path: p.join(directory.path, safeName),
      mimeType: mimeType,
      userAgent: userAgent,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      status: DownloadStatus.queued,
    );
    _items = [item, ..._items];
    await _persist(item);
    notifyListeners();
    await _run(item);
  }

  Future<void> _run(DownloadItem item) async {
    final path = item.path;
    if (path == null) return;

    final token = CancelToken();
    _tokens[item.id] = token;
    _pausing[item.id] = false;

    final file = File(path);
    var existing = 0;
    try {
      if (item.receivedBytes > 0 && await file.exists()) {
        existing = await file.length();
      } else if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      existing = 0;
    }
    if (existing > 0) {
      item.receivedBytes = existing;
    } else {
      item.receivedBytes = 0;
    }

    final headers = <String, dynamic>{};
    if (existing > 0) headers['Range'] = 'bytes=$existing-';
    if (item.userAgent != null && item.userAgent!.isNotEmpty) {
      headers['User-Agent'] = item.userAgent;
    }

    item.status = DownloadStatus.running;
    item.error = null;
    notifyListeners();
    await _persist(item);

    RandomAccessFile? handle;
    try {
      final response = await _dio.get<ResponseBody>(
        item.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
        cancelToken: token,
      );

      final body = response.data;
      if (body == null) {
        throw const HttpException('Empty response');
      }

      final contentLength = int.tryParse(
              response.headers.value(Headers.contentLengthHeader) ?? '') ??
          0;
      item.totalBytes =
          existing > 0 && contentLength > 0 ? existing + contentLength : contentLength;

      handle = await file.open(
          mode: existing > 0 ? FileMode.append : FileMode.write);

      await for (final chunk in body.stream) {
        await handle.writeFrom(chunk);
        item.receivedBytes += chunk.length;
        _onTick(item);
      }
      await handle.flush();
      await handle.close();
      handle = null;

      item.status = DownloadStatus.completed;
      if (item.totalBytes <= 0) item.totalBytes = item.receivedBytes;
      await _persist(item);
      notifyListeners();
      _tokens.remove(item.id);
      await _notifyComplete(item);
    } on DioException catch (error) {
      if (handle != null) {
        try {
          await handle.close();
        } catch (_) {}
      }
      handle = null;
      _tokens.remove(item.id);
      if (CancelToken.isCancel(error)) {
        final wasPause = _pausing[item.id] ?? false;
        item.status = wasPause ? DownloadStatus.paused : DownloadStatus.cancelled;
        item.error = wasPause ? null : 'Cancelled';
      } else {
        item.status = DownloadStatus.failed;
        item.error = _describeError(error);
      }
      await _persist(item);
      notifyListeners();
      if (item.status == DownloadStatus.failed) await _notifyFailed(item);
    } catch (error) {
      if (handle != null) {
        try {
          await handle.close();
        } catch (_) {}
      }
      handle = null;
      _tokens.remove(item.id);
      item.status = DownloadStatus.failed;
      item.error = error.toString();
      await _persist(item);
      notifyListeners();
      await _notifyFailed(item);
    }
  }

  String _describeError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return 'Connection timed out';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.badResponse:
        return 'Server returned ${error.response?.statusCode ?? 'an error'}';
      case DioExceptionType.badCertificate:
        return 'Invalid server certificate';
      case DioExceptionType.cancel:
        return 'Cancelled';
      case DioExceptionType.unknown:
        return error.message ?? 'Download failed';
    }
  }

  void _onTick(DownloadItem item) {
    final now = DateTime.now();
    final last = _lastTick[item.id];
    if (last != null && now.difference(last).inMilliseconds < 350) return;
    _lastTick[item.id] = now;
    notifyListeners();
    _persist(item);
    if (_settings.settings.notifyProgress) {
      _notifications.showProgress(
        id: _notificationId(item),
        filename: item.filename,
        received: item.receivedBytes,
        total: item.totalBytes,
      );
    }
  }

  int _notificationId(DownloadItem item) =>
      item.id.hashCode & 0x7fffffff;

  Future<void> _notifyComplete(DownloadItem item) async {
    if (_settings.settings.notifyComplete) {
      await _notifications.showComplete(
        id: _notificationId(item),
        filename: item.filename,
      );
    }
  }

  Future<void> _notifyFailed(DownloadItem item) async {
    if (_settings.settings.notifyFailed) {
      await _notifications.showFailed(
        id: _notificationId(item),
        filename: item.filename,
        reason: item.error,
      );
    }
  }

  // --------------------------------------------------------------- controls

  Future<void> pause(DownloadItem item) async {
    final token = _tokens[item.id];
    if (token == null) return;
    _pausing[item.id] = true;
    token.cancel('paused');
  }

  Future<void> resume(DownloadItem item) async {
    if (item.status != DownloadStatus.paused && item.status != DownloadStatus.failed) {
      return;
    }
    await _run(item);
  }

  Future<void> cancel(DownloadItem item) async {
    final token = _tokens[item.id];
    _pausing[item.id] = false;
    if (token != null) {
      token.cancel('cancelled');
    } else {
      item.status = DownloadStatus.cancelled;
      await _persist(item);
      notifyListeners();
    }
  }

  Future<void> retry(DownloadItem item) async {
    final path = item.path;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    item.receivedBytes = 0;
    item.totalBytes = 0;
    item.error = null;
    await _run(item);
  }

  Future<void> remove(DownloadItem item, {bool deleteFile = false}) async {
    if (deleteFile) {
      final path = item.path;
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    await _notifications.cancel(_notificationId(item));
    try {
      await _db.deleteDownload(item.id);
    } catch (_) {}
    _items = _items.where((entry) => entry.id != item.id).toList();
    notifyListeners();
  }

  Future<void> clearFinishedRecords() async {
    try {
      await _db.clearDownloadRecords();
      _items = _items
          .where((item) =>
              item.status == DownloadStatus.running ||
              item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.paused)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> openFile(DownloadItem item) async {
    final path = item.path;
    if (path == null) return 'File is not available';
    if (!await File(path).exists()) return 'File was deleted';
    try {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) return null;
      return result.message.isEmpty
          ? 'No app can open this file'
          : result.message;
    } catch (error) {
      return 'Could not open file: $error';
    }
  }

  Future<void> shareFile(DownloadItem item) async {
    final path = item.path;
    if (path == null) return;
    if (!await File(path).exists()) return;
    await Share.shareXFiles([XFile(path)], subject: item.filename);
  }

  // ---------------------------------------------------------------- helpers

  Future<void> _persist(DownloadItem item) async {
    try {
      await _db.saveDownload(item);
    } catch (_) {}
  }

  Future<Directory> _downloadDirectory() async {
    Directory base;
    try {
      final external = await getExternalStorageDirectory();
      base = external ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      base = await getApplicationDocumentsDirectory();
    }
    final directory = Directory(p.join(base.path, 'Tavrix Downloads'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> _uniqueFilename(Directory directory, String filename) async {
    final cleaned = filename
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'^\s+|\s+$'), '');
    final base = cleaned.isEmpty ? 'download' : cleaned;
    var candidate = base;
    var counter = 1;
    while (await File(p.join(directory.path, candidate)).exists()) {
      final dot = base.lastIndexOf('.');
      if (dot > 0) {
        candidate =
            '${base.substring(0, dot)} ($counter)${base.substring(dot)}';
      } else {
        candidate = '$base ($counter)';
      }
      counter++;
      if (counter > 200) break;
    }
    return candidate;
  }

  @override
  void dispose() {
    for (final token in _tokens.values) {
      try {
        token.cancel('provider disposed');
      } catch (_) {}
    }
    super.dispose();
  }
}
