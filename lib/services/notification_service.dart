import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channels and download notifications.
class NotificationService {
  static const String channelActive = 'tavrix_active_downloads';
  static const String channelComplete = 'tavrix_download_completed';
  static const String channelErrors = 'tavrix_download_errors';
  static const String channelWebsite = 'tavrix_website_notifications';
  static const String channelAlerts = 'tavrix_browser_alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool get isReady => _ready;

  /// Called with the payload of a tapped notification, e.g. `download:<id>`.
  void Function(String payload)? onNotificationTap;

  Future<void> init() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTap?.call(payload);
          }
        },
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelActive,
        'Active downloads',
        description: 'Live progress for running downloads',
        importance: Importance.low,
        playSound: false,
        showBadge: false,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelComplete,
        'Download completed',
        description: 'Shown when a download finishes',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelErrors,
        'Download errors',
        description: 'Shown when a download fails',
        importance: Importance.high,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelWebsite,
        'Website notifications',
        description: 'Notifications sent by websites you allowed',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelAlerts,
        'Browser alerts',
        description: 'Tavrix alerts and warnings',
        importance: Importance.defaultImportance,
      ));

      _ready = true;
    } catch (_) {
      // Notifications are optional: downloads must keep working without them.
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details(
    String channelId,
    String channelName, {
    bool ongoing = false,
    bool showProgress = false,
    bool indeterminate = false,
    int maxProgress = 100,
    int progress = 0,
    Importance importance = Importance.low,
    Priority priority = Priority.low,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelName,
        importance: importance,
        priority: priority,
        ongoing: ongoing,
        autoCancel: !ongoing,
        onlyAlertOnce: true,
        showProgress: showProgress,
        indeterminate: indeterminate,
        maxProgress: maxProgress,
        progress: progress,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  Future<void> showProgress({
    required int id,
    required String filename,
    required int received,
    required int total,
  }) async {
    if (!_ready) return;
    final hasTotal = total > 0;
    final percent = hasTotal ? ((received / total) * 100).clamp(0, 100).floor() : 0;
    try {
      await _plugin.show(
        id: id,
        title: filename,
        body: hasTotal
            ? '$percent%  -  ${_formatBytes(received)} / ${_formatBytes(total)}'
            : 'Downloading... ${_formatBytes(received)}',
        notificationDetails: _details(
          channelActive,
          'Active downloads',
          ongoing: true,
          showProgress: hasTotal,
          indeterminate: !hasTotal,
          maxProgress: hasTotal ? total : 100,
          progress: hasTotal ? received : 0,
        ),
        payload: 'downloads',
      );
    } catch (_) {
      // Ignore notification failures; the download itself is unaffected.
    }
  }

  Future<void> showComplete({
    required int id,
    required String filename,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: 'Download complete',
        body: filename,
        notificationDetails: _details(
          channelComplete,
          'Download completed',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        payload: 'downloads',
      );
    } catch (_) {}
  }

  Future<void> showFailed({
    required int id,
    required String filename,
    String? reason,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: 'Download failed',
        body: reason == null || reason.isEmpty ? filename : '$filename - $reason',
        notificationDetails: _details(
          channelErrors,
          'Download errors',
          importance: Importance.high,
          priority: Priority.high,
        ),
        payload: 'downloads',
      );
    } catch (_) {}
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(
          channelAlerts,
          'Browser alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }
}
