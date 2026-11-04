import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material 3 built on the Tavrix tokens. Dark is the primary, designed theme;
/// light is derived from the same scale so nothing looks like a template.
class AppTheme {
  AppTheme._();

  static ThemeData dark(int accent, {bool animations = true}) => _build(
        accent: Color(accent),
        brightness: Brightness.dark,
        animations: animations,
      );

  static ThemeData light(int accent, {bool animations = true}) => _build(
        accent: Color(accent),
        brightness: Brightness.light,
        animations: animations,
      );

  static ThemeData _build({
    required Color accent,
    required Brightness brightness,
    required bool animations,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: isDark ? TvColors.canvas : const Color(0xFFF6F7F9),
      onSurface: isDark ? TvColors.textPrimary : const Color(0xFF14171C),
      surfaceContainerLowest: isDark ? TvColors.canvas : Colors.white,
      surfaceContainerLow: isDark ? TvColors.surface : Colors.white,
      surfaceContainer: isDark ? TvColors.surfaceRaised : const Color(0xFFF0F2F5),
      surfaceContainerHigh: isDark ? TvColors.surfaceRaised : Colors.white,
      surfaceContainerHighest:
          isDark ? TvColors.surfaceHighest : const Color(0xFFE7EAEF),
      onSurfaceVariant: isDark ? TvColors.textSecondary : const Color(0xFF5C6470),
      outline: isDark ? TvColors.strokeStrong : const Color(0xFFC9CED6),
      outlineVariant: isDark ? TvColors.stroke : const Color(0xFFE2E5EA),
      error: TvColors.danger,
      errorContainer: TvColors.dangerSoft,
      onErrorContainer: const Color(0xFFFFD9DC),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        headlineSmall: TvText.display.copyWith(
          color: scheme.onSurface,
        ),
        titleLarge: TvText.title.copyWith(color: scheme.onSurface),
        titleMedium: TvText.title.copyWith(
          fontSize: 16,
          color: scheme.onSurface,
        ),
        titleSmall: TvText.section.copyWith(color: scheme.onSurfaceVariant),
        bodyLarge: TvText.body.copyWith(color: scheme.onSurface),
        bodyMedium: TvText.bodyMuted.copyWith(color: scheme.onSurfaceVariant),
        bodySmall: TvText.caption.copyWith(color: scheme.onSurfaceVariant),
        labelLarge: TvText.label.copyWith(color: scheme.onSurface),
        labelMedium: TvText.label.copyWith(color: scheme.onSurfaceVariant),
        labelSmall: TvText.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: TvSpace.page,
        titleTextStyle: TvText.title.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.lg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
        ),
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TvSpace.md,
          vertical: TvSpace.xs,
        ),
        minVerticalPadding: TvSpace.sm,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: TvSpace.xl),
          textStyle: TvText.label.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TvRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TvText.label.copyWith(fontWeight: FontWeight.w600),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TvRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TvRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TvSpace.lg,
          vertical: TvSpace.md,
        ),
        hintStyle: TvText.body.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TvText.label.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TvSpace.md,
          vertical: TvSpace.sm,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TvRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.lg),
        ),
        titleTextStyle: TvText.title.copyWith(color: scheme.onSurface),
        contentTextStyle: TvText.bodyMuted.copyWith(color: scheme.onSurfaceVariant),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
        ),
        textStyle: TvText.body.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TvText.body.copyWith(color: scheme.onSurface),
        actionTextColor: scheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 3,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
        labelStyle: TvText.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TvText.label,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvRadius.lg),
        ),
      ),
      pageTransitionsTheme: animations
          ? const PageTransitionsTheme()
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _InstantTransitionsBuilder(),
                TargetPlatform.iOS: _InstantTransitionsBuilder(),
                TargetPlatform.macOS: _InstantTransitionsBuilder(),
                TargetPlatform.windows: _InstantTransitionsBuilder(),
                TargetPlatform.linux: _InstantTransitionsBuilder(),
              },
            ),
    );
  }
}

/// Screen transitions with no animation, used when the user turns animations
/// off in settings.
class _InstantTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
