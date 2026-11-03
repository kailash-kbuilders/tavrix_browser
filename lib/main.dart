import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/bookmark_provider.dart';
import 'providers/browser_provider.dart';
import 'providers/download_provider.dart';
import 'providers/history_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DatabaseService();
  await database.init();

  final settings = SettingsProvider();
  await settings.load();

  final notifications = NotificationService();
  await notifications.init();

  final browser = BrowserProvider(db: database, settings: settings);
  await browser.restoreSession();

  final downloads = DownloadProvider(
    db: database,
    settings: settings,
    notifications: notifications,
  );
  await downloads.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: database),
        Provider<NotificationService>.value(value: notifications),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<BrowserProvider>.value(value: browser),
        ChangeNotifierProvider<DownloadProvider>.value(value: downloads),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (context) => BookmarkProvider(database)..load(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (context) => HistoryProvider(database),
        ),
        ChangeNotifierProvider<PermissionProvider>(
          create: (context) => PermissionProvider(database)..load(),
        ),
      ],
      child: TavrixApp(notifications: notifications),
    ),
  );
}
