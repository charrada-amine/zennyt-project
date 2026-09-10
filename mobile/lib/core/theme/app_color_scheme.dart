import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP COLOR SCHEME — ThemeExtension
/// Semantic color tokens that adapt to light/dark mode.
/// All values extracted from the Figma Color System (FigmaColors/).
///
/// Usage: `context.colors.scaffoldBg` or
///        `Theme.of(context).extension<AppColorScheme>()!.scaffoldBg`
/// ──────────────────────────────────────────────────────────────────────────────

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    // ── Surfaces (Figma: Surfaces) ──
    required this.panelBackground,
    required this.scaffoldBg,
    required this.cardSurface,
    required this.surfaceRaised,
    required this.sidebarNav,

    // ── Text (Figma: Typography Colors) ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textAccent,
    required this.textDarkBlue,
    required this.textMuted,

    // ── Dividers / Borders (Figma: Borders & Separators) ──
    required this.divider,
    required this.dividerThick,
    required this.border,
    required this.separator,

    // ── Back Button ──
    required this.backButtonBg,
    required this.backButtonBorder,
    required this.backButtonIcon,

    // ── Action Cards ──
    required this.actionCardFilled,
    required this.actionCardOutlineBg,
    required this.actionCardOutlineBorder,
    required this.actionCardOutlineText,

    // ── Settings Menu ──
    required this.chevron,
    required this.menuLabelText,

    // ── Navigation ──
    required this.navBg,
    required this.navBorder,
    required this.navLabelSelected,
    required this.navLabelUnselected,

    // ── Interactive States (Figma: Interactive States) ──
    required this.activeBg,
    required this.activeText,
    required this.hoverBg,
    required this.toggleOn,
    required this.toggleOff,

    // ── General UI ──
    required this.iconDefault,
    required this.iconDisabled,
    required this.shadowColor,
    required this.inputFill,
    required this.placeholderBg,

    // ── Brand / Status (Figma: Brand & Semantic) ──
    required this.primary,
    required this.brandNavy,
    required this.brandIndigo,
    required this.accent,
    required this.error,
    required this.success,
    required this.successBg,
    required this.dangerBg,
    required this.info,
    required this.onPrimary,

    // ── Poll & Post Features ──
    required this.pollSelectedBg,
    required this.pollSelectedBorder,
    required this.pollUnselectedBorder,
    required this.pollOptionTextSelected,
    required this.pollOptionTextUnselected,
    required this.pollPercentageText,

    // ── Links & Documents ──
    required this.linkColor,
    required this.mediaErrorBg,
    required this.documentBg,
  });

  // ── Surfaces ──
  final Color panelBackground;
  final Color scaffoldBg;
  final Color cardSurface;
  final Color surfaceRaised;
  final Color sidebarNav;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textAccent;
  final Color textDarkBlue;
  final Color textMuted;

  // ── Dividers / Borders ──
  final Color divider;
  final Color dividerThick;
  final Color border;
  final Color separator;

  // ── Back Button ──
  final Color backButtonBg;
  final Color backButtonBorder;
  final Color backButtonIcon;

  // ── Action Cards ──
  final Color actionCardFilled;
  final Color actionCardOutlineBg;
  final Color actionCardOutlineBorder;
  final Color actionCardOutlineText;

  // ── Settings Menu ──
  final Color chevron;
  final Color menuLabelText;

  // ── Navigation ──
  final Color navBg;
  final Color navBorder;
  final Color navLabelSelected;
  final Color navLabelUnselected;

  // ── Interactive States ──
  final Color activeBg;
  final Color activeText;
  final Color hoverBg;
  final Color toggleOn;
  final Color toggleOff;

  // ── General UI ──
  final Color iconDefault;
  final Color iconDisabled;
  final Color shadowColor;
  final Color inputFill;
  final Color placeholderBg;

  // ── Brand / Status ──
  final Color primary;
  final Color brandNavy;
  final Color brandIndigo;
  final Color accent;
  final Color error;
  final Color success;
  final Color successBg;
  final Color dangerBg;
  final Color info;
  final Color onPrimary;

  // ── Poll & Post Features ──
  final Color pollSelectedBg;
  final Color pollSelectedBorder;
  final Color pollUnselectedBorder;
  final Color pollOptionTextSelected;
  final Color pollOptionTextUnselected;
  final Color pollPercentageText;

  // ── Links & Documents ──
  final Color linkColor;
  final Color mediaErrorBg;
  final Color documentBg;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT SCHEME — Figma Light Mode
  // ═══════════════════════════════════════════════════════════════════════════

  static const light = AppColorScheme(
    // Surfaces
    panelBackground: Color(0xFFFFFFFF),        // Surface
    scaffoldBg: Color(0xFFF9FBFF),             // App Background
    cardSurface: Color(0xFFFFFFFF),            // Surface
    surfaceRaised: Color(0xFFFFFFFF),          // Surface Raised
    sidebarNav: Color(0xFFFFFFFF),             // Sidebar / Nav

    // Text
    textPrimary: Color(0xFF111827),            // Text Primary
    textSecondary: Color(0xFF6B7280),          // Text Secondary
    textTertiary: Color(0xFF9CA3AF),           // Text Tertiary
    textAccent: Color(0xFF11428D),             // Text Accent
    textDarkBlue: Color(0xFF11428D),           // Brand Navy
    textMuted: Color(0xFF9CA3AF),              // Text Tertiary

    // Dividers / Borders
    divider: Color(0xFFF3F4F6),               // Separator
    dividerThick: Color(0xFFE5E7EB),          // slightly heavier divider
    border: Color(0x14000000),                 // Border rgba(0,0,0,0.08)
    separator: Color(0xFFF3F4F6),             // Separator

    // Back Button
    backButtonBg: Color(0xFFFFFFFF),
    backButtonBorder: Color(0x14000000),        // Border token
    backButtonIcon: Color(0xFF111827),          // Text Primary

    // Action Cards
    actionCardFilled: Color(0xFFD12E7D),       // accent magenta
    actionCardOutlineBg: Color(0xFFFFFFFF),
    actionCardOutlineBorder: Color(0xFF11428D), // Brand Navy
    actionCardOutlineText: Color(0xFF11428D),

    // Settings Menu
    chevron: Color(0xFFD1D5DB),                // Chevron
    menuLabelText: Color(0xFF111827),          // Text Primary

    // Navigation
    navBg: Color(0xFFFFFFFF),                  // Sidebar / Nav
    navBorder: Color(0xFFF3F4F6),             // Separator
    navLabelSelected: Color(0xFF4F46E5),       // Active Text / Brand Indigo
    navLabelUnselected: Color(0xFF9CA3AF),     // Text Tertiary

    // Interactive States
    activeBg: Color(0xFFEEF2FF),              // Active BG
    activeText: Color(0xFF4F46E5),             // Active Text
    hoverBg: Color(0xFFF9FAFB),               // Hover BG
    toggleOn: Color(0xFF22C55E),              // Toggle ON
    toggleOff: Color(0xFFD1D5DB),             // Toggle OFF

    // General UI
    iconDefault: Color(0xFF111827),            // Text Primary
    iconDisabled: Color(0xFFD1D5DB),           // Chevron
    shadowColor: Color(0x14000000),            // Border token
    inputFill: Color(0xFFF3F4F6),             // Input Fill
    placeholderBg: Color(0xFFF3F4F6),         // Input Fill

    // Brand / Status
    primary: Color(0xFF11428D),               // Brand Navy
    brandNavy: Color(0xFF11428D),             // Brand Navy
    brandIndigo: Color(0xFF4F46E5),           // Brand Indigo
    accent: Color(0xFFD12E7D),                // accent magenta
    error: Color(0xFFEF4444),                 // Danger
    success: Color(0xFF22C55E),               // Success
    successBg: Color(0xFFF0FDF4),             // Success BG
    dangerBg: Color(0xFFFEF2F2),             // Danger BG
    info: Color(0xFF3B82F6),                  // info blue
    onPrimary: Color(0xFFFFFFFF),

    // Poll
    pollSelectedBg: Color(0xFFEEF2FF),        // Active BG
    pollSelectedBorder: Color(0xFF11428D),     // Brand Navy
    pollUnselectedBorder: Color(0xFFD1D5DB),  // Chevron
    pollOptionTextSelected: Color(0xFF111827), // Text Primary
    pollOptionTextUnselected: Color(0xFF6B7280), // Text Secondary
    pollPercentageText: Color(0xFF9CA3AF),     // Text Tertiary

    // Links & Documents
    linkColor: Color(0xFF3B82F6),             // info blue
    mediaErrorBg: Color(0xFFD1D5DB),          // Chevron
    documentBg: Color(0xFFF3F4F6),            // Input Fill
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK SCHEME — Figma Dark Mode
  // ═══════════════════════════════════════════════════════════════════════════

  static const dark = AppColorScheme(
    // Surfaces
    panelBackground: Color(0xFF1E1E24),        // Surface dark
    scaffoldBg: Color(0xFF141418),             // App Background dark
    cardSurface: Color(0xFF1E1E24),            // Surface dark
    surfaceRaised: Color(0xFF252529),          // Surface Raised dark
    sidebarNav: Color(0xFF1E1E24),             // Sidebar / Nav dark

    // Text
    textPrimary: Color(0xFFFFFFFF),            // Text Primary dark
    textSecondary: Color(0xFF8A8A9A),          // Text Secondary dark
    textTertiary: Color(0xFF555560),           // Text Tertiary dark
    textAccent: Color(0xFF818CF8),             // Text Accent dark
    textDarkBlue: Color(0xFFFFFFFF),           // white in dark mode
    textMuted: Color(0xFF555560),              // Text Tertiary dark

    // Dividers / Borders
    divider: Color(0xFF2A2A30),               // Separator dark
    dividerThick: Color(0xFF2A2A30),
    border: Color(0x14FFFFFF),                 // Border dark rgba(255,255,255,0.08)
    separator: Color(0xFF2A2A30),             // Separator dark

    // Back Button
    backButtonBg: Color(0xFF252529),           // Surface Raised dark
    backButtonBorder: Color(0x14FFFFFF),        // Border dark
    backButtonIcon: Color(0xFFFFFFFF),

    // Action Cards
    actionCardFilled: Color(0xFF818CF8),       // Brand Indigo dark
    actionCardOutlineBg: Color(0xFF1E1E24),    // Surface dark
    actionCardOutlineBorder: Color(0xFF555560), // Text Tertiary dark
    actionCardOutlineText: Color(0xFFFFFFFF),

    // Settings Menu
    chevron: Color(0xFF48484A),               // Chevron dark
    menuLabelText: Color(0xFFFFFFFF),

    // Navigation
    navBg: Color(0xFF1E1E24),                 // Sidebar / Nav dark
    navBorder: Color(0xFF2A2A30),             // Separator dark
    navLabelSelected: Color(0xFF818CF8),       // Active Text dark / Brand Indigo dark
    navLabelUnselected: Color(0xFF555560),     // Text Tertiary dark

    // Interactive States
    activeBg: Color(0xFF1E1E2E),              // Active BG dark
    activeText: Color(0xFF818CF8),             // Active Text dark
    hoverBg: Color(0xFF252529),               // Hover BG dark
    toggleOn: Color(0xFF22C55E),              // Toggle ON (same)
    toggleOff: Color(0xFF3A3A3E),             // Toggle OFF dark

    // General UI
    iconDefault: Color(0xFFFFFFFF),
    iconDisabled: Color(0xFF555560),           // Text Tertiary dark
    shadowColor: Color(0x00000000),            // invisible in dark mode
    inputFill: Color(0xFF252529),             // Input Fill dark
    placeholderBg: Color(0xFF252529),

    // Brand / Status
    primary: Color(0xFF818CF8),               // Brand Indigo dark (primary CTA in dark)
    brandNavy: Color(0xFF11428D),             // Brand Navy (unchanged)
    brandIndigo: Color(0xFF818CF8),           // Brand Indigo dark
    accent: Color(0xFFD12E7D),                // accent magenta (unchanged)
    error: Color(0xFFEF4444),                 // Danger (same)
    success: Color(0xFF22C55E),               // Success (same)
    successBg: Color(0x1A22C55E),             // Success BG dark ~10% opacity
    dangerBg: Color(0x1AEF4444),             // Danger BG dark ~10% opacity
    info: Color(0xFF60A5FA),                  // lighter info for dark
    onPrimary: Color(0xFFFFFFFF),

    // Poll
    pollSelectedBg: Color(0xFF1E1E2E),        // Active BG dark
    pollSelectedBorder: Color(0xFF818CF8),     // Brand Indigo dark
    pollUnselectedBorder: Color(0xFF48484A),   // Chevron dark
    pollOptionTextSelected: Color(0xFFFFFFFF),
    pollOptionTextUnselected: Color(0xFF8A8A9A), // Text Secondary dark
    pollPercentageText: Color(0xFF555560),      // Text Tertiary dark

    // Links & Documents
    linkColor: Color(0xFF60A5FA),              // lighter info for dark
    mediaErrorBg: Color(0xFF2A2A30),          // Separator dark
    documentBg: Color(0xFF252529),            // Input Fill dark
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME EXTENSION OVERRIDES
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  AppColorScheme copyWith({
    Color? panelBackground,
    Color? scaffoldBg,
    Color? cardSurface,
    Color? surfaceRaised,
    Color? sidebarNav,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textAccent,
    Color? textDarkBlue,
    Color? textMuted,
    Color? divider,
    Color? dividerThick,
    Color? border,
    Color? separator,
    Color? backButtonBg,
    Color? backButtonBorder,
    Color? backButtonIcon,
    Color? actionCardFilled,
    Color? actionCardOutlineBg,
    Color? actionCardOutlineBorder,
    Color? actionCardOutlineText,
    Color? chevron,
    Color? menuLabelText,
    Color? navBg,
    Color? navBorder,
    Color? navLabelSelected,
    Color? navLabelUnselected,
    Color? activeBg,
    Color? activeText,
    Color? hoverBg,
    Color? toggleOn,
    Color? toggleOff,
    Color? iconDefault,
    Color? iconDisabled,
    Color? shadowColor,
    Color? inputFill,
    Color? placeholderBg,
    Color? primary,
    Color? brandNavy,
    Color? brandIndigo,
    Color? accent,
    Color? error,
    Color? success,
    Color? successBg,
    Color? dangerBg,
    Color? info,
    Color? onPrimary,
    Color? pollSelectedBg,
    Color? pollSelectedBorder,
    Color? pollUnselectedBorder,
    Color? pollOptionTextSelected,
    Color? pollOptionTextUnselected,
    Color? pollPercentageText,
    Color? linkColor,
    Color? mediaErrorBg,
    Color? documentBg,
  }) {
    return AppColorScheme(
      panelBackground: panelBackground ?? this.panelBackground,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardSurface: cardSurface ?? this.cardSurface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      sidebarNav: sidebarNav ?? this.sidebarNav,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textAccent: textAccent ?? this.textAccent,
      textDarkBlue: textDarkBlue ?? this.textDarkBlue,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      dividerThick: dividerThick ?? this.dividerThick,
      border: border ?? this.border,
      separator: separator ?? this.separator,
      backButtonBg: backButtonBg ?? this.backButtonBg,
      backButtonBorder: backButtonBorder ?? this.backButtonBorder,
      backButtonIcon: backButtonIcon ?? this.backButtonIcon,
      actionCardFilled: actionCardFilled ?? this.actionCardFilled,
      actionCardOutlineBg: actionCardOutlineBg ?? this.actionCardOutlineBg,
      actionCardOutlineBorder:
          actionCardOutlineBorder ?? this.actionCardOutlineBorder,
      actionCardOutlineText:
          actionCardOutlineText ?? this.actionCardOutlineText,
      chevron: chevron ?? this.chevron,
      menuLabelText: menuLabelText ?? this.menuLabelText,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      navLabelSelected: navLabelSelected ?? this.navLabelSelected,
      navLabelUnselected: navLabelUnselected ?? this.navLabelUnselected,
      activeBg: activeBg ?? this.activeBg,
      activeText: activeText ?? this.activeText,
      hoverBg: hoverBg ?? this.hoverBg,
      toggleOn: toggleOn ?? this.toggleOn,
      toggleOff: toggleOff ?? this.toggleOff,
      iconDefault: iconDefault ?? this.iconDefault,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      shadowColor: shadowColor ?? this.shadowColor,
      inputFill: inputFill ?? this.inputFill,
      placeholderBg: placeholderBg ?? this.placeholderBg,
      primary: primary ?? this.primary,
      brandNavy: brandNavy ?? this.brandNavy,
      brandIndigo: brandIndigo ?? this.brandIndigo,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      dangerBg: dangerBg ?? this.dangerBg,
      info: info ?? this.info,
      onPrimary: onPrimary ?? this.onPrimary,
      pollSelectedBg: pollSelectedBg ?? this.pollSelectedBg,
      pollSelectedBorder: pollSelectedBorder ?? this.pollSelectedBorder,
      pollUnselectedBorder: pollUnselectedBorder ?? this.pollUnselectedBorder,
      pollOptionTextSelected:
          pollOptionTextSelected ?? this.pollOptionTextSelected,
      pollOptionTextUnselected:
          pollOptionTextUnselected ?? this.pollOptionTextUnselected,
      pollPercentageText: pollPercentageText ?? this.pollPercentageText,
      linkColor: linkColor ?? this.linkColor,
      mediaErrorBg: mediaErrorBg ?? this.mediaErrorBg,
      documentBg: documentBg ?? this.documentBg,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      sidebarNav: Color.lerp(sidebarNav, other.sidebarNav, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      textDarkBlue: Color.lerp(textDarkBlue, other.textDarkBlue, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      dividerThick: Color.lerp(dividerThick, other.dividerThick, t)!,
      border: Color.lerp(border, other.border, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      backButtonBg: Color.lerp(backButtonBg, other.backButtonBg, t)!,
      backButtonBorder: Color.lerp(
        backButtonBorder,
        other.backButtonBorder,
        t,
      )!,
      backButtonIcon: Color.lerp(backButtonIcon, other.backButtonIcon, t)!,
      actionCardFilled: Color.lerp(
        actionCardFilled,
        other.actionCardFilled,
        t,
      )!,
      actionCardOutlineBg: Color.lerp(
        actionCardOutlineBg,
        other.actionCardOutlineBg,
        t,
      )!,
      actionCardOutlineBorder: Color.lerp(
        actionCardOutlineBorder,
        other.actionCardOutlineBorder,
        t,
      )!,
      actionCardOutlineText: Color.lerp(
        actionCardOutlineText,
        other.actionCardOutlineText,
        t,
      )!,
      chevron: Color.lerp(chevron, other.chevron, t)!,
      menuLabelText: Color.lerp(menuLabelText, other.menuLabelText, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navLabelSelected: Color.lerp(
        navLabelSelected,
        other.navLabelSelected,
        t,
      )!,
      navLabelUnselected: Color.lerp(
        navLabelUnselected,
        other.navLabelUnselected,
        t,
      )!,
      activeBg: Color.lerp(activeBg, other.activeBg, t)!,
      activeText: Color.lerp(activeText, other.activeText, t)!,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t)!,
      toggleOn: Color.lerp(toggleOn, other.toggleOn, t)!,
      toggleOff: Color.lerp(toggleOff, other.toggleOff, t)!,
      iconDefault: Color.lerp(iconDefault, other.iconDefault, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      placeholderBg: Color.lerp(placeholderBg, other.placeholderBg, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      brandIndigo: Color.lerp(brandIndigo, other.brandIndigo, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      pollSelectedBg: Color.lerp(pollSelectedBg, other.pollSelectedBg, t)!,
      pollSelectedBorder:
          Color.lerp(pollSelectedBorder, other.pollSelectedBorder, t)!,
      pollUnselectedBorder:
          Color.lerp(pollUnselectedBorder, other.pollUnselectedBorder, t)!,
      pollOptionTextSelected:
          Color.lerp(pollOptionTextSelected, other.pollOptionTextSelected, t)!,
      pollOptionTextUnselected: Color.lerp(
          pollOptionTextUnselected, other.pollOptionTextUnselected, t)!,
      pollPercentageText:
          Color.lerp(pollPercentageText, other.pollPercentageText, t)!,
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
      mediaErrorBg: Color.lerp(mediaErrorBg, other.mediaErrorBg, t)!,
      documentBg: Color.lerp(documentBg, other.documentBg, t)!,
    );
  }
}

/// Convenience extension so widgets can write `context.colors.scaffoldBg`
/// instead of `Theme.of(context).extension<AppColorScheme>()!.scaffoldBg`.
extension AppColorSchemeX on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}
