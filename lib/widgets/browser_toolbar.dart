import 'package:flutter/material.dart';

/// Bottom or top navigation toolbar.
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: canGoBack ? onBack : null,
          ),
          IconButton(
            tooltip: 'Forward',
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            onPressed: canGoForward ? onForward : null,
          ),
          IconButton(
            tooltip: isLoading ? 'Stop' : 'Reload',
            icon: Icon(
              isLoading ? Icons.close_rounded : Icons.refresh_rounded,
              size: 22,
            ),
            onPressed: onReload,
          ),
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_rounded, size: 22),
            onPressed: onHome,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: onTabs,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isPrivate
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$tabCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPrivate ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}
