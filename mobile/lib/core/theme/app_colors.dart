import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP COLOR PALETTE
/// Extracted from the Figma Color System (FigmaColors/ reference screenshots)
///
/// All values are the EXACT hex tokens from the Figma palette.
/// Light → Dark correspondences are documented inline.
/// Icon colors are identical across both modes (design decision).
/// ──────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand identity — dark navy blue (same in both modes)
  static const Color brandNavy = Color(0xFF11428D);

  /// CTA buttons, active states — indigo
  /// Light: #4F46E5 | Dark: #818CF8
  static const Color brandIndigo = Color(0xFF4F46E5);
  static const Color brandIndigoDark = Color(0xFF818CF8);

  // Legacy aliases for backward compatibility
  static const Color primary = brandNavy;
  static const Color primaryDark = Color(0xFF0E3672);
  static const Color primaryLight = Color(0xFF1A5BB0);
  static const Color primaryDeep = Color(0xFF0A2E5C);
  static const Color primaryDarkest = Color(0xFF001D55);

  // Primary with opacity variants
  static const Color primary80 = Color(0xCC11428D);
  static const Color primary60 = Color(0x9911428D);
  static const Color primary40 = Color(0x6611428D);
  static const Color primary20 = Color(0x3311428D);
  static const Color primary10 = Color(0x1A11428D);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT / CTA COLORS — MAGENTA / PINK
  // Used for primary action buttons, section header underlines, key CTAs
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color accent = Color(0xFFD12E7D);
  static const Color accentDark = Color(0xFFB0256A);
  static const Color accentLight = Color(0xFFDE5A97);
  static const Color accentSoft = Color(0xFFFCE4EC);
  static const Color magentaDark = Color(0xFF681E53);

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY / INDIGO
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color secondary = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF818CF8);
  static const Color secondaryLighter = Color(0xFF9DA6FA);
  static const Color secondaryBright = Color(0xFF685EFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // PURPLE ACCENT
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color purple = Color(0xFF9747FF);
  static const Color purpleLight = Color(0xFFB388FF);
  static const Color purpleSoft = Color(0xFFE8DEFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACE & BACKGROUND COLORS (Figma tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Light mode ──
  /// App Background — Canvas behind all content
  static const Color appBackground = Color(0xFFF9FBFF);

  /// Surface — Cards, panels, sheets
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface Raised — Popovers, modals, elevated
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Sidebar / Nav — Left nav background
  static const Color sidebarNav = Color(0xFFFFFFFF);

  // ── Dark mode ──
  /// App Background dark
  static const Color appBackgroundDark = Color(0xFF141418);

  /// Surface dark — Cards, panels, sheets
  static const Color surfaceDark = Color(0xFF1E1E24);

  /// Surface Raised dark — Popovers, modals, elevated
  static const Color surfaceRaisedDark = Color(0xFF252529);

  /// Sidebar / Nav dark
  static const Color sidebarNavDark = Color(0xFF1E1E24);

  // Legacy aliases
  static const Color background = appBackground;
  static const Color backgroundAlt = Color(0xFFF9FBFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceCool = Color(0xFFF3F4F6);
  static const Color surfaceWarm = Color(0xFFF9FAFB);
  static const Color darkBackground = appBackgroundDark;
  static const Color darkSurface = surfaceDark;
  static const Color darkSurfaceVariant = surfaceRaisedDark;

  // Dark overlay for modals, bottom sheets
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x33000000);

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY COLORS (Figma tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Light ──
  /// Text Primary — Headings, main labels
  static const Color textPrimary = Color(0xFF111827);

  /// Text Secondary — Descriptions, subtitles
  static const Color textSecondary = Color(0xFF6B7280);

  /// Text Tertiary — Placeholders, hints
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text Accent — Nav active, links
  static const Color textAccent = Color(0xFF11428D);

  // ── Dark ──
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8A8A9A);
  static const Color textTertiaryDark = Color(0xFF555560);
  static const Color textAccentDark = Color(0xFF818CF8);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDERS & SEPARATORS (Figma tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Light ──
  /// Border — Card borders (rgba(0,0,0,0.08))
  static const Color border = Color(0x14000000);

  /// Separator — List row dividers
  static const Color separator = Color(0xFFF3F4F6);

  /// Input Fill — Input background
  static const Color inputFill = Color(0xFFF3F4F6);

  /// Chevron — List row arrows
  static const Color chevron = Color(0xFFD1D5DB);

  // ── Dark ──
  /// Border dark (rgba(255,255,255,0.08))
  static const Color borderDark = Color(0x14FFFFFF);

  /// Separator dark
  static const Color separatorDark = Color(0xFF2A2A30);

  /// Input Fill dark
  static const Color inputFillDark = Color(0xFF252529);

  /// Chevron dark
  static const Color chevronDark = Color(0xFF48484A);

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTIVE STATES (Figma tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Light ──
  /// Active BG — Selected nav item
  static const Color activeBg = Color(0xFFEEF2FF);

  /// Active Text — Selected nav label/icon
  static const Color activeText = Color(0xFF4F46E5);

  /// Hover BG — Row hover state
  static const Color hoverBg = Color(0xFFF9FAFB);

  // ── Dark ──
  static const Color activeBgDark = Color(0xFF1E1E2E);
  static const Color activeTextDark = Color(0xFF818CF8);
  static const Color hoverBgDark = Color(0xFF252529);

  // ── Toggles (same in both modes unless noted) ──
  /// Toggle ON — green, same in both modes
  static const Color toggleOn = Color(0xFF22C55E);

  /// Toggle OFF — inactive toggle track
  static const Color toggleOff = Color(0xFFD1D5DB);
  static const Color toggleOffDark = Color(0xFF3A3A3E);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC / STATUS COLORS (Figma tokens)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success — Positive change, verified (same in both modes)
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF15803D);
  static const Color successLight = Color(0xFF4ADE80);

  /// Success BG — light: #F0FDF4, dark: rgba(34,197,94,0.1)
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBgDark = Color(0x1A22C55E);
  static const Color successSoft = successBg;

  /// Danger / Error — same in both modes
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFF87171);

  /// Danger BG — light: #FEF2F2, dark: rgba(239,68,68,0.1)
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBgDark = Color(0x1AEF4444);
  static const Color errorSoft = dangerBg;

  /// Warning
  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFFFA000);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningSoft = Color(0xFFFFF8E1);

  /// Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON COLOR SYSTEM (Figma tokens — unchanged across modes)
  // Colorful rounded-square icon backgrounds
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hired candidates
  static const Color iconHired = Color(0xFF7C3AED);

  /// Account Center
  static const Color iconAccount = Color(0xFFEC4899);

  /// Notifications
  static const Color iconNotification = Color(0xFF3B82F6);

  /// Theme toggle (Dark / Light)
  static const Color iconTheme = Color(0xFF111827);

  /// Accessibility
  static const Color iconAccess = Color(0xFF8B5CF6);

  /// Plans & Pricing
  static const Color iconPricing = Color(0xFFF472B6);

  /// Help / Support
  static const Color iconHelp = Color(0xFF2563EB);

  /// Terms & Conditions / Legal
  static const Color iconLegal = Color(0xFF6B7280);

  /// Log out
  static const Color iconLogout = Color(0xFF1E3A8A);

  /// Verified / Positive (Success icon)
  static const Color iconSuccess = Color(0xFF10B981);

  // Legacy icon aliases for backward compatibility
  static const Color iconPurple = iconHired;
  static const Color iconPink = iconAccount;
  static const Color iconBlue = iconNotification;
  static const Color iconBlack = iconTheme;
  static const Color iconDeepPurple = iconAccess;
  static const Color iconMediumBlue = iconHelp;
  static const Color iconGrey = iconLegal;
  static const Color iconNavy = iconLogout;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL / GRAY SCALE
  // Mapped to Figma typography / border tokens
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color black = Color(0xFF000000);
  static const Color gray900 = Color(0xFF111827); // = textPrimary
  static const Color gray850 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray550 = Color(0xFF555560);
  static const Color gray500 = Color(0xFF6B7280); // = textSecondary
  static const Color gray450 = Color(0xFF9CA3AF); // = textTertiary
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray350 = Color(0xFFD1D5DB); // = chevron
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6); // = separator / inputFill
  static const Color gray50 = Color(0xFFF9FAFB);  // = hoverBg
  static const Color white = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL FEATURE & PANEL COLORS (backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color iconColor = Color(0xFF11428D);
  static const Color chipSelected = Color(0xFF11428D);
  static const Color chipUnselected = Color(0xFFF3F4F6);
  static const Color panelBackground = Colors.white;
  static const Color primaryGrey = Color(0xFF6B7280);
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryPink = Color(0xFFD12E7D);
  static const Color subtitleColor = Color(0xFF6B7280);
  static const Color hiringTagBg = Color(0xFFEEF2FF);
  static const Color hiringTagText = Color(0xFF11428D);
  static const Color itemDivider = Color(0xFFF3F4F6);
  static const Color itemDividerDark = Color(0xFF2A2A30);

  static const Color textDark = Color(0xFF111827);
  static const Color textMuted2 = Color(0xFF6B7280);
  static const Color surfaceLight = Color(0xFFF9FBFF);
  static const Color selectedBg = Color(0xFFEEF2FF);
  static const Color linkBlue = Color(0xFF3B82F6);
  static const Color dividerThin = Color(0xFFF3F4F6);
  static const Color cardShadow = Color(0x0F212125);
  static const Color backBtnBorder = Color(0x14000000);

  static const Color textDarkBlue = Color(0xFF11428D);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL UI ELEMENT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Navigation Bar
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarActive = Color(0xFF4F46E5);
  static const Color navBarInactive = Color(0xFF9CA3AF);

  // Chat Bubbles
  static const Color chatBubbleSent = Color(0xFF11428D);
  static const Color chatBubbleReceived = Color(0xFFF3F4F6);
  static const Color chatBubbleSentText = Color(0xFFFFFFFF);
  static const Color chatBubbleReceivedText = Color(0xFF111827);

  // Badges & Tags
  static const Color badge = Color(0xFFEF4444);
  static const Color tagBackground = Color(0xFFEEF2FF);
  static const Color tagText = Color(0xFF4F46E5);

  // Swipe Card Colors
  static const Color swipeLike = Color(0xFF22C55E);
  static const Color swipeDislike = Color(0xFFEF4444);
  static const Color swipeSuperLike = Color(0xFF4F46E5);
  static const Color swipeBoost = Color(0xFF9747FF);

  // Online Status
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color busy = Color(0xFFFFC107);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11428D), Color(0xFF1A5BB0)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD12E7D), Color(0xFF9747FF)],
  );

  static const LinearGradient indigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1E24), Color(0xFF141418)],
  );

  static const LinearGradient sectionHeaderGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF11428D), Color(0xFF1A5BB0)],
  );

  // Shimmer / Loading gradient
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFF3F4F6), Color(0xFFF9FBFF), Color(0xFFF3F4F6)],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // MATERIAL COLOR SWATCH (for MaterialApp theme)
  // Based on Brand Navy #11428D
  // ═══════════════════════════════════════════════════════════════════════════

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF11428D,
    <int, Color>{
      50: Color(0xFFE3EAF5),
      100: Color(0xFFB9CCE6),
      200: Color(0xFF8BABD5),
      300: Color(0xFF5D8AC4),
      400: Color(0xFF3B71B7),
      500: Color(0xFF11428D), // Primary
      600: Color(0xFF0F3B80),
      700: Color(0xFF0C3270),
      800: Color(0xFF0A2A61),
      900: Color(0xFF061C44),
    },
  );
}
