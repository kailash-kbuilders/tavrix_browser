import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'screens/browser_screen.dart';
import 'screens/downloads_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// Global navigator key so a tapped notification can open Downloads.
final GlobalKey<NavigatorState> tavrixNavigatorKey =
    GlobalKey<NavigatorState>();

class TavrixApp extends StatefulWidget {
  const TavrixApp({super.key, required this.notifications});

  final NotificationService notifications;

  @override
  State<TavrixApp> createState() => _TavrixAppState();
}

class _TavrixAppState extends State<TavrixApp> {
  @override
  void initState() {
    super.initState();
    widget.notifications.onNotificationTap = (payload) {
      tavrixNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (context) => const DownloadsScreen()),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final app = settings.settings;

    return MaterialApp(
      navigatorKey: tavrixNavigatorKey,
      title: TavrixConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(app.accentColor, animations: app.animations),
      darkTheme: AppTheme.dark(app.accentColor, animations: app.animations),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(app.fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const BrowserScreen(),
    );
  }
}
