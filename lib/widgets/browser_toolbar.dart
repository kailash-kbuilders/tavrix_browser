import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Bottom navigation bar: back, forward, reload, home, tabs and menu.
class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onHome,
    required this.onTabs,
    required this.onMenu,
    required this.tabCount,
    required this.isPrivate,
    required this.onReload,
    required this.isLoading,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onHome;
  final VoidCallback onTabs;
  final VoidCallback onMenu;
  final int tabCount;
  final bool isPrivate;
  final VoidCallback onReload;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget button(
      IconData icon,
      String tooltip,
      VoidCallback? onTap, {
      bool emphasised = false,
    }) {
      final enabled = onTap != null;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TvRadius.md),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Icon(
              icon,
              size: 21,
              color: enabled
                  ? (emphasised ? scheme.primary : scheme.onSurface)
                  : scheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TvSpace.sm,
        vertical: TvSpace.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          button(
            Icons.arrow_back_ios_new_rounded,
            'Back',
            canGoBack ? onBack : null,
          ),
          button(
            Icons.arrow_forward_ios_rounded,
            'Forward',
            canGoForward ? onForward : null,
          ),
          button(
            isLoading ? Icons.close_rounded : Icons.refresh_rounded,
            isLoading ? 'Stop' : 'Reload',
            onReload,
          ),
          button(Icons.home_outlined, 'Home', onHome),
          InkWell(
            onTap: onTabs,
            borderRadius: BorderRadius.circular(TvRadius.sm),
            child: Container(
              height: 30,
              constraints: const BoxConstraints(minWidth: 30),
              padding: const EdgeInsets.symmetric(horizontal: TvSpace.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TvRadius.sm),
                border: Border.all(
                  color: isPrivate
                      ? TvColors.privateAccent.withValues(alpha: 0.8)
                      : scheme.outline,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$tabCount',
                style: TvText.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPrivate ? TvColors.privateAccent : scheme.onSurface,
                ),
              ),
            ),
          ),
          button(Icons.more_vert_rounded, 'Menu', onMenu),
        ],
      ),
    );
  }
}
