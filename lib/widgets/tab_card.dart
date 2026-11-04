import 'package:flutter/material.dart';

import '../models/tab_model.dart';
import '../theme/tokens.dart';
import '../utils/url_utils.dart';
import 'ui/tv_widgets.dart';

/// A tab in the tab overview: real screenshot when available, otherwise a clean
/// tinted fallback - never an empty card.
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
    final hasPreview = tab.thumbnail != null;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(TvRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPreview)
              Image.memory(
                tab.thumbnail!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tab.isPrivate
                        ? [
                            TvColors.privateAccent.withValues(alpha: 0.22),
                            scheme.surfaceContainer,
                          ]
                        : [
                            scheme.primary.withValues(alpha: 0.14),
                            scheme.surfaceContainer,
                          ],
                  ),
                ),
              ),
            // Scrim so the title stays readable over any screenshot.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: hasPreview ? 0.35 : 0.05),
                    Colors.black.withValues(alpha: hasPreview ? 0.78 : 0.25),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TvSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TvFavicon(url: tab.url, size: 24, radius: TvRadius.sm),
                      const Spacer(),
                      if (tab.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: TvSpace.xs),
                          child: Icon(Icons.push_pin_rounded, size: 13),
                        ),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close_rounded, size: 16),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    domain.isEmpty ? 'New tab' : domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            if (tab.isLoading)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}
