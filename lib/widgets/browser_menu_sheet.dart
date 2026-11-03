import 'package:flutter/material.dart';

enum BrowserMenuAction {
  newTab,
  newPrivateTab,
  bookmarks,
  history,
  downloads,
  notifications,
  findInPage,
  translate,
  readerMode,
  desktopSite,
  saveOffline,
  addToHome,
  pageInfo,
  autofill,
  share,
  privacy,
  sitePermissions,
  settings,
}

/// The browser menu. Every entry maps to a real action handled by
/// BrowserScreen.
class BrowserMenuSheet extends StatelessWidget {
  const BrowserMenuSheet({
    super.key,
    required this.onSelected,
    required this.isDesktopMode,
    required this.isPrivate,
    required this.canAutofill,
  });

  final ValueChanged<BrowserMenuAction> onSelected;
  final bool isDesktopMode;
  final bool isPrivate;
  final bool canAutofill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(IconData icon, String label, BrowserMenuAction action) {
      return ListTile(
        leading: Icon(icon, size: 22),
        title: Text(label),
        onTap: () {
          Navigator.of(context).pop();
          onSelected(action);
        },
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('Menu', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (isPrivate)
                    Chip(
                      label: const Text('Private'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                ],
              ),
            ),
            item(Icons.add_rounded, 'New tab', BrowserMenuAction.newTab),
            item(Icons.lock_outline_rounded, 'New private tab',
                BrowserMenuAction.newPrivateTab),
            const Divider(height: 12),
            item(Icons.bookmark_border_rounded, 'Bookmarks',
                BrowserMenuAction.bookmarks),
            item(Icons.history_rounded, 'History', BrowserMenuAction.history),
            item(Icons.download_rounded, 'Downloads',
                BrowserMenuAction.downloads),
            item(Icons.notifications_none_rounded, 'Notifications',
                BrowserMenuAction.notifications),
            const Divider(height: 12),
            item(Icons.search_rounded, 'Find in page',
                BrowserMenuAction.findInPage),
            item(Icons.translate_rounded, 'Translate page',
                BrowserMenuAction.translate),
            item(Icons.chrome_reader_mode_outlined, 'Reader mode',
                BrowserMenuAction.readerMode),
            item(
              isDesktopMode ? Icons.smartphone_rounded : Icons.desktop_windows_outlined,
              isDesktopMode ? 'Mobile site' : 'Desktop site',
              BrowserMenuAction.desktopSite,
            ),
            item(Icons.cloud_download_outlined, 'Save page offline',
                BrowserMenuAction.saveOffline),
            item(Icons.add_to_home_screen_outlined, 'Add to home screen',
                BrowserMenuAction.addToHome),
            item(Icons.key_rounded, 'Autofill saved login',
                BrowserMenuAction.autofill),
            const Divider(height: 12),
            item(Icons.share_rounded, 'Share page', BrowserMenuAction.share),
            item(Icons.info_outline_rounded, 'Page information',
                BrowserMenuAction.pageInfo),
            item(Icons.shield_outlined, 'Privacy and security',
                BrowserMenuAction.privacy),
            item(Icons.tune_rounded, 'Site permissions',
                BrowserMenuAction.sitePermissions),
            item(Icons.settings_outlined, 'Settings', BrowserMenuAction.settings),
          ],
        ),
      ),
    );
  }
}
