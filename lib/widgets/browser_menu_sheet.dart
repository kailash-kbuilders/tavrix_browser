import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ui/tv_widgets.dart';

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

/// The browser menu, grouped so it reads as three short lists instead of one
/// long one.
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
    final scheme = Theme.of(context).colorScheme;

    Widget row(IconData icon, String label, BrowserMenuAction action,
        {Color? tint}) {
      return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onSelected(action);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TvSpace.page,
            vertical: TvSpace.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint ?? scheme.onSurfaceVariant),
              const SizedBox(width: TvSpace.lg),
              Expanded(
                child: Text(
                  label,
                  style: TvText.body.copyWith(
                    color: tint ?? scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget divider() => Divider(
          height: 1,
          indent: TvSpace.page,
          endIndent: TvSpace.page,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: TvSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvSpace.page,
                TvSpace.sm,
                TvSpace.page,
                TvSpace.md,
              ),
              child: Row(
                children: [
                  const TvBrandMark(compact: true),
                  const Spacer(),
                  if (isPrivate)
                    const TvPill(
                      label: 'Private',
                      icon: Icons.shield_moon_outlined,
                      color: TvColors.privateAccent,
                    ),
                ],
              ),
            ),
            divider(),
            row(Icons.add_rounded, 'New tab', BrowserMenuAction.newTab),
            row(Icons.shield_moon_outlined, 'New private tab',
                BrowserMenuAction.newPrivateTab,
                tint: TvColors.privateAccent),
            divider(),
            row(Icons.bookmark_border_rounded, 'Bookmarks',
                BrowserMenuAction.bookmarks),
            row(Icons.history_rounded, 'History', BrowserMenuAction.history),
            row(Icons.download_outlined, 'Downloads',
                BrowserMenuAction.downloads),
            row(Icons.notifications_none_rounded, 'Notifications',
                BrowserMenuAction.notifications),
            divider(),
            row(Icons.search_rounded, 'Find in page',
                BrowserMenuAction.findInPage),
            row(Icons.translate_rounded, 'Translate page',
                BrowserMenuAction.translate),
            row(Icons.chrome_reader_mode_outlined, 'Reader mode',
                BrowserMenuAction.readerMode),
            row(
              isDesktopMode
                  ? Icons.smartphone_rounded
                  : Icons.desktop_windows_outlined,
              isDesktopMode ? 'Mobile site' : 'Desktop site',
              BrowserMenuAction.desktopSite,
            ),
            row(Icons.cloud_download_outlined, 'Save page offline',
                BrowserMenuAction.saveOffline),
            row(Icons.add_to_home_screen_outlined, 'Add to home screen',
                BrowserMenuAction.addToHome),
            if (canAutofill)
              row(Icons.key_rounded, 'Autofill saved login',
                  BrowserMenuAction.autofill),
            divider(),
            row(Icons.share_rounded, 'Share page', BrowserMenuAction.share),
            row(Icons.info_outline_rounded, 'Page information',
                BrowserMenuAction.pageInfo),
            row(Icons.shield_outlined, 'Privacy and security',
                BrowserMenuAction.privacy),
            row(Icons.tune_rounded, 'Site permissions',
                BrowserMenuAction.sitePermissions),
            row(Icons.settings_outlined, 'Settings', BrowserMenuAction.settings),
          ],
        ),
      ),
    );
  }
}
