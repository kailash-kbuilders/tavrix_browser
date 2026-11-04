import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../utils/url_utils.dart';

/// Section label with an optional text action. Used on every screen.
class TvSectionHeader extends StatelessWidget {
  const TvSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      TvSpace.page,
      TvSpace.xl,
      TvSpace.page,
      TvSpace.sm,
    ),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: TvText.section),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TvSpace.sm,
                  vertical: TvSpace.xs,
                ),
                child: Text(
                  action!,
                  style: TvText.label.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact icon + label action, used in the home quick-action row.
class TvActionTile extends StatelessWidget {
  const TvActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TvRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TvSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(TvRadius.md),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(icon, size: 21, color: scheme.onSurface),
                ),
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(TvRadius.pill),
                      ),
                      child: Text(
                        badge!,
                        style: TvText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TvSpace.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TvText.label,
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft square icon button used in headers and toolbars.
class TvIconButton extends StatelessWidget {
  const TvIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 38,
    this.iconSize = 20,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TvRadius.md),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: filled ? scheme.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(TvRadius.md),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap == null
              ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
              : scheme.onSurface,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Standard list row: soft icon tile, title, subtitle, trailing widget.
class TvRow extends StatelessWidget {
  const TvRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.iconColor,
    this.iconWidget,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final Color? iconColor;
  final Widget? iconWidget;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(TvRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TvSpace.page,
          vertical: dense ? TvSpace.sm : TvSpace.md,
        ),
        child: Row(
          children: [
            Container(
              height: dense ? 34 : 40,
              width: dense ? 34 : 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(TvRadius.sm),
              ),
              alignment: Alignment.center,
              child: iconWidget ??
                  Icon(
                    icon,
                    size: dense ? 17 : 19,
                    color: iconColor ?? scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: TvSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.body.copyWith(
                      fontSize: dense ? 14 : 15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.bodyMuted,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: TvSpace.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state with icon, headline, explanation and an optional action.
class TvEmptyState extends StatelessWidget {
  const TvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TvSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(TvRadius.lg),
              ),
              child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: TvSpace.lg),
            Text(title, style: TvText.title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: TvSpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TvText.bodyMuted,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: TvSpace.lg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Site icon with a graceful letter fallback, no third-party favicon service.
class TvFavicon extends StatelessWidget {
  const TvFavicon({
    super.key,
    required this.url,
    this.size = 46,
    this.radius,
    this.fallbackLabel,
  });

  final String url;
  final double size;
  final double? radius;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final host = UrlUtils.hostOf(url);
    final letter = (fallbackLabel ?? UrlUtils.suggestTitle(url))
        .characters
        .first
        .toUpperCase();
    final corner = radius ?? TvRadius.md;

    Widget fallback() => Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(corner),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        );

    if (host.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(corner),
      child: Container(
        height: size,
        width: size,
        color: scheme.surfaceContainerHighest,
        padding: EdgeInsets.all(size * 0.18),
        child: Image.network(
          'https://$host/favicon.ico',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => fallback(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : fallback(),
        ),
      ),
    );
  }
}

/// Small Tavrix identity: logo mark plus wordmark.
class TvBrandMark extends StatelessWidget {
  const TvBrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: compact ? 26 : 30,
          width: compact ? 26 : 30,
          decoration: BoxDecoration(
            color: const Color(0xFF070A12),
            borderRadius: BorderRadius.circular(TvRadius.sm),
          ),
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            'assets/branding/logo_mark.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: TvSpace.sm),
        Text(
          'Tavrix',
          style: TvText.title.copyWith(
            fontSize: compact ? 15 : 17,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Rounded pill used for small status labels.
class TvPill extends StatelessWidget {
  const TvPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TvSpace.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(TvRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TvText.caption.copyWith(
              color: tint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
