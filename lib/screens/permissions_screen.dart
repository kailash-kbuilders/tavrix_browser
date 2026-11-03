import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/site_permission.dart';
import '../providers/permission_provider.dart';
import '../services/permission_service.dart';

/// Permission dashboard: Android OS permissions on top, per-website decisions
/// below. The two are always kept separate.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionProvider>().load();
    });
  }

  String _statusLabel(PermissionStatus? status) {
    if (status == null) return 'Unknown';
    if (status.isGranted) return 'Allowed';
    if (status.isPermanentlyDenied) return 'Blocked in settings';
    if (status.isDenied) return 'Not allowed';
    if (status.isRestricted) return 'Restricted';
    if (status.isLimited) return 'Limited';
    return 'Unknown';
  }

  Future<void> _request(String key) async {
    switch (key) {
      case 'camera':
        await PermissionService.requestCamera();
        break;
      case 'microphone':
        await PermissionService.requestMicrophone();
        break;
      case 'location':
        await PermissionService.requestLocation();
        break;
      case 'notifications':
        await PermissionService.requestNotifications();
        break;
    }
    if (!mounted) return;
    await context.read<PermissionProvider>().refreshOsStatus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PermissionProvider>();
    final theme = Theme.of(context);
    final sites = provider.sites;
    final hosts = <String>{for (final site in sites) site.host}.toList()..sort();

    Widget osTile(String key, String title, String purpose, IconData icon) {
      final status = provider.osStatus(key);
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('${_statusLabel(status)} - $purpose'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status?.isGranted != true)
              TextButton(
                onPressed: () => _request(key),
                child: const Text('Allow'),
              ),
            const IconButton(
              tooltip: 'Android settings',
              icon: Icon(Icons.settings_outlined, size: 20),
              onPressed: PermissionService.openSystemSettings,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        actions: [
          IconButton(
            tooltip: 'Reset website permissions',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: provider.resetAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Android permissions',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Requested only when a feature needs them - never at launch.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          osTile('camera', 'Camera', 'QR scanning and site camera use',
              Icons.camera_alt_outlined),
          osTile('microphone', 'Microphone', 'Voice search and site audio',
              Icons.mic_none_rounded),
          osTile('location', 'Location', 'Sites that ask for your position',
              Icons.place_outlined),
          osTile('notifications', 'Notifications', 'Download progress and alerts',
              Icons.notifications_none_rounded),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Website permissions',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Granting the Android permission does not grant any website '
              'access. Each site is decided separately.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (hosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No website has asked for a permission yet'),
              ),
            )
          else
            for (final host in hosts)
              ExpansionTile(
                title: Text(host),
                subtitle: Text(
                  '${sites.where((site) => site.host == host).length} permission(s)',
                ),
                children: [
                  for (final site in sites.where((site) => site.host == host))
                    ListTile(
                      title: Text(site.permission),
                      trailing: DropdownButton<SiteDecision>(
                        value: site.decision,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: SiteDecision.allow, child: Text('Allow')),
                          DropdownMenuItem(
                              value: SiteDecision.block, child: Text('Block')),
                          DropdownMenuItem(
                              value: SiteDecision.ask, child: Text('Ask')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          provider.setDecision(host, site.permission, value);
                        },
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Reset this site'),
                    onTap: () => provider.resetSite(host),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
