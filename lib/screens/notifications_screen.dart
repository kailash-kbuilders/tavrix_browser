import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/settings_provider.dart';
import '../services/permission_service.dart';
import 'downloads_screen.dart';

/// In-app notification centre for downloads, alerts and website permissions.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadProvider>();
    final settings = context.watch<SettingsProvider>();
    final permissions = context.watch<PermissionProvider>();
    final theme = Theme.of(context);

    final active = downloads.items
        .where((item) => item.status == DownloadStatus.running)
        .toList();
    final completed = downloads.items
        .where((item) => item.status == DownloadStatus.completed)
        .take(20)
        .toList();
    final failed = downloads.items
        .where((item) =>
            item.status == DownloadStatus.failed ||
            item.status == DownloadStatus.cancelled)
        .take(20)
        .toList();
    final websitePermissions = permissions.sites
        .where((site) => site.permission == 'notifications')
        .toList();

    Widget section(String title, List<Widget> children) {
      if (children.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(title,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          ...children,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          const IconButton(
            tooltip: 'Notification settings',
            icon: Icon(Icons.settings_outlined),
            onPressed: PermissionService.openSystemSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Download progress'),
                  value: settings.settings.notifyProgress,
                  onChanged: settings.setNotifyProgress,
                ),
                SwitchListTile(
                  title: const Text('Download complete'),
                  value: settings.settings.notifyComplete,
                  onChanged: settings.setNotifyComplete,
                ),
                SwitchListTile(
                  title: const Text('Download failed'),
                  value: settings.settings.notifyFailed,
                  onChanged: settings.setNotifyFailed,
                ),
                SwitchListTile(
                  title: const Text('Website notifications'),
                  value: settings.settings.notifyWebsite,
                  onChanged: settings.setNotifyWebsite,
                ),
              ],
            ),
          ),
          section(
            'Active downloads',
            [
              for (final item in active)
                ListTile(
                  leading: const Icon(Icons.downloading_rounded),
                  title: Text(item.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: LinearProgressIndicator(
                    value: item.totalBytes > 0 ? item.progress : null,
                    minHeight: 3,
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (context) => const DownloadsScreen())),
                ),
            ],
          ),
          section(
            'Completed downloads',
            [
              for (final item in completed)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: Text(item.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Completed'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (context) => const DownloadsScreen())),
                ),
            ],
          ),
          section(
            'Failed downloads',
            [
              for (final item in failed)
                ListTile(
                  leading: Icon(Icons.error_outline_rounded,
                      color: theme.colorScheme.error),
                  title: Text(item.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.error ?? item.statusLabel),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (context) => const DownloadsScreen())),
                ),
            ],
          ),
          section(
            'Websites allowed to notify',
            [
              for (final site in websitePermissions)
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: Text(site.host),
                  subtitle: Text(site.decision.name),
                ),
            ],
          ),
          if (active.isEmpty && completed.isEmpty && failed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nothing here yet')),
            ),
        ],
      ),
    );
  }
}
