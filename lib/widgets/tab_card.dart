import 'package:flutter/material.dart';

import '../models/tab_model.dart';
import '../utils/url_utils.dart';

/// A tab card used in the tab overview grid.
class TabCard extends StatelessWidget {
  const TabCard({
    super.key,
    required this.tab,
    required this.onTap,
    required this.onLongPress,
    required this.onClose,
  });

  final TabModel tab;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domain = UrlUtils.hostOf(tab.url);
    final letter = tab.title.isEmpty
        ? (domain.isEmpty ? '?' : domain[0].toUpperCase())
        : tab.title[0].toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (tab.isPrivate) ...[
                      const SizedBox(height: 6),
                      Icon(Icons.shield_moon_outlined,
                          size: 14, color: theme.colorScheme.primary),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab.title.isEmpty ? 'New tab' : tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.groupName == null
                              ? domain
                              : '${tab.groupName} - $domain',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tab.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.push_pin_rounded, size: 14),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
