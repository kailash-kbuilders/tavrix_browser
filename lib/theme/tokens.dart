import 'package:flutter/material.dart';

/// Tavrix design tokens: one place for colour, spacing, radii and type.
/// Every screen uses these so the app reads as one product.
class TvColors {
  TvColors._();

  /// Near-black canvas with a blue undertone, not flat #000.
  static const Color canvas = Color(0xFF0A0C11);
  static const Color surface = Color(0xFF111419);
  static const Color surfaceRaised = Color(0xFF171B22);
  static const Color surfaceHighest = Color(0xFF1E232C);
  static const Color stroke = Color(0xFF232A35);
  static const Color strokeStrong = Color(0xFF2E3745);

  /// Signature accent: a calm electric blue.
  static const Color accent = Color(0xFF5C7CFA);
  static const Color accentSoft = Color(0xFF1B2540);
  static const Color accentText = Color(0xFFA8B8FF);

  static const Color textPrimary = Color(0xFFEDEFF4);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textTertiary = Color(0xFF6C7686);

  static const Color success = Color(0xFF3FBF8F);
  static const Color warning = Color(0xFFE0A24A);
  static const Color danger = Color(0xFFEF5F6B);
  static const Color dangerSoft = Color(0xFF35191D);

  static const Color privateAccent = Color(0xFF9B7BFF);
}

/// 8-point spacing system.
class TvSpace {
  TvSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Standard horizontal page padding.
  static const double page = 20;
}

class TvRadius {
  TvRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// Type scale. Sizes are deliberately few so hierarchy stays consistent.
class TvText {
  TvText._();

  static const TextStyle display = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: TvColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: TvColors.textPrimary,
  );

  static const TextStyle section = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: TvColors.textTertiary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: TvColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: TvColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: TvColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w400,
    color: TvColors.textTertiary,
  );
}
