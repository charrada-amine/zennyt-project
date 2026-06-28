import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP TYPOGRAPHY
/// Extracted from the Figma Design (Design.jpg)
///
/// Typography system based on the design's text hierarchy.
/// The design uses a clean sans-serif font family (Inter/Roboto-like).
/// ──────────────────────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILY
  // The design uses a modern sans-serif. Inter is recommended as the closest
  // match. Add 'inter' to pubspec.yaml or use Google Fonts package.
  // ═══════════════════════════════════════════════════════════════════════════

  static const String fontFamily = 'Inter';
  static const String fontFamilyFallback = 'Roboto';

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT SIZES
  // Extracted from the design's text hierarchy
  // ═══════════════════════════════════════════════════════════════════════════

  static const double fontSizeXxs = 10.0; // Micro labels, timestamps
  static const double fontSizeXs = 11.0; // Badge text, tiny labels
  static const double fontSizeSm = 12.0; // Caption text, helper text
  static const double fontSizeMd = 14.0; // Body text, list items
  static const double fontSizeLg = 16.0; // Subtitle, emphasized body
  static const double fontSizeXl = 18.0; // Section titles
  static const double fontSizeXxl = 20.0; // Screen titles
  static const double fontSize2xl = 24.0; // Large headings
  static const double fontSize3xl = 28.0; // Hero headings
  static const double fontSize4xl = 32.0; // Display text
  static const double fontSize5xl = 40.0; // Extra large display

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT WEIGHTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // ═══════════════════════════════════════════════════════════════════════════
  // LINE HEIGHTS (multipliers)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double lineHeightTight = 1.1;
  static const double lineHeightSnug = 1.25;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // ═══════════════════════════════════════════════════════════════════════════
  // LETTER SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.25;
  static const double letterSpacingWider = 0.5;
  static const double letterSpacingWidest = 1.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-DEFINED TEXT STYLES
  // Complete set of text styles matching the design hierarchy
  // ═══════════════════════════════════════════════════════════════════════════

  // --- Display / Hero ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize5xl,
    fontWeight: bold,
    height: lineHeightTight,
    letterSpacing: letterSpacingTight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize4xl,
    fontWeight: bold,
    height: lineHeightTight,
    letterSpacing: letterSpacingTight,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize3xl,
    fontWeight: semiBold,
    height: lineHeightSnug,
    letterSpacing: letterSpacingTight,
  );

  // --- Headings ---
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize2xl,
    fontWeight: bold,
    height: lineHeightSnug,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxl,
    fontWeight: semiBold,
    height: lineHeightSnug,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXl,
    fontWeight: semiBold,
    height: lineHeightNormal,
  );

  // --- Titles ---
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxl,
    fontWeight: semiBold,
    height: lineHeightSnug,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: semiBold,
    height: lineHeightNormal,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: semiBold,
    height: lineHeightNormal,
  );

  // --- Body ---
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  // --- Labels ---
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWider,
  );

  // --- Captions & Helper ---
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: regular,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWidest,
  );

  // --- Button Text ---
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWider,
  );

  // --- Navigation ---
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxs,
    fontWeight: medium,
    height: lineHeightNormal,
  );

  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  // --- Chat ---
  static const TextStyle chatMessage = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: regular,
    height: lineHeightRelaxed,
  );

  static const TextStyle chatTimestamp = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxs,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  // --- Input / Form ---
  static const TextStyle inputText = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: regular,
    height: lineHeightNormal,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: medium,
    height: lineHeightNormal,
  );

  static const TextStyle inputError = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: regular,
    height: lineHeightNormal,
  );
}
