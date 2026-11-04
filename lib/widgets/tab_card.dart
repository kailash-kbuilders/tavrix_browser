import 'package:flutter/material.dart';

import '../models/tab_model.dart';
import '../theme/tokens.dart';
import '../utils/url_utils.dart';
import 'ui/tv_widgets.dart';

/// A tab in the tab overview grid.
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
    final scheme = Theme.of(context).colorScheme;
    final domain = UrlUtils.hostOf(tab.url).replaceFirst('www.', '');
    final title = UrlUtils.cleanTitle(tab.title, tab.url);

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(TvRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(TvSpace.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tab.isPrivate
                        ? [
                            TvColors.privateAccent.withValues(alpha: 0.18),
                            scheme.surfaceContainer,
                          ]
                        : [
                            scheme.primary.withValues(alpha: 0.10),
                            scheme.surfaceContainer,
                          ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TvFavicon(url: tab.url, size: 26, radius: TvRadius.sm),
                        const Spacer(),
                        if (tab.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: TvSpace.xs),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        GestureDetector(
                          onTap: onClose,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (tab.isPrivate)
                      const Padding(
                        padding: EdgeInsets.only(bottom: TvSpace.xs),
                        child: TvPill(
                          label: 'Private',
                          icon: Icons.shield_moon_outlined,
                          color: TvColors.privateAccent,
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.label.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvSpace.md,
                TvSpace.sm,
                TvSpace.md,
                TvSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tab.groupName == null || domain.isEmpty
                          ? (domain.isEmpty ? 'New tab' : domain)
                          : '${tab.groupName} · $domain',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.caption,
                    ),
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
