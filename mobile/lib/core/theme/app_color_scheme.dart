import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP COLOR SCHEME — ThemeExtension
/// Semantic color tokens that adapt to light/dark mode.
///
/// Usage: `context.colors.scaffoldBg` or
///        `Theme.of(context).extension<AppColorScheme>()!.scaffoldBg`
/// ──────────────────────────────────────────────────────────────────────────────

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    // ── Backgrounds ──
    required this.panelBackground,
    required this.scaffoldBg,
    required this.cardSurface,

    // ── Text ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textDarkBlue,
    required this.textMuted,

    // ── Dividers / Borders ──
    required this.divider,
    required this.dividerThick,
    required this.border,

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

    // ── General UI ──
    required this.iconDefault,
    required this.iconDisabled,
    required this.shadowColor,
    required this.inputFill,
    required this.placeholderBg,

    // ── Brand / Status ──
    required this.primary,
    required this.accent,
    required this.error,
    required this.success,
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

  // ── Backgrounds ──
  final Color panelBackground;
  final Color scaffoldBg;
  final Color cardSurface;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textDarkBlue;
  final Color textMuted;

  // ── Dividers / Borders ──
  final Color divider;
  final Color dividerThick;
  final Color border;

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

  // ── General UI ──
  final Color iconDefault;
  final Color iconDisabled;
  final Color shadowColor;
  final Color inputFill;
  final Color placeholderBg;

  // ── Brand / Status ──
  final Color primary;
  final Color accent;
  final Color error;
  final Color success;
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
  // LIGHT SCHEME
  // ═══════════════════════════════════════════════════════════════════════════

  static const light = AppColorScheme(
    panelBackground: Color(0xFFFFFFFF),
    scaffoldBg: Color(0xFFFFFFFF),
    cardSurface: Color(0xFFFFFFFF),

    textPrimary: Color(0xFF232323),
    textSecondary: Color(0xFF7C8393),
    textDarkBlue: Color(0xFF283266),
    textMuted: Color(0xFF7A8191),

    divider: Color(0xFFF1F1F5),
    dividerThick: Color(0xFFEEEEEE),
    border: Color(0xFFEEEEEE),

    backButtonBg: Color(0xFFFFFFFF),
    backButtonBorder: Color(0xFFEEEEEE),
    backButtonIcon: Color(0xFF232323),

    actionCardFilled: Color(0xFFD6317A),
    actionCardOutlineBg: Color(0xFFFFFFFF),
    actionCardOutlineBorder: Color(0xFF283266),
    actionCardOutlineText: Color(0xFF283266),

    chevron: Color(0xFFA2AEC4),
    menuLabelText: Color(0xFF283266),

    navBg: Color(0xFFFFFFFF),
    navBorder: Color(0xFFEEEEEE),
    navLabelSelected: Color(0xFF21438A),
    navLabelUnselected: Color(0xFF7C8393),

    iconDefault: Color(0xFF232323),
    iconDisabled: Color(0xFFC7C7C7),
    shadowColor: Color(0x14000000),
    inputFill: Color(0xFFF3F3F3),
    placeholderBg: Color(0xFFF3F3F3),

    primary: Color(0xFF21438A),
    accent: Color(0xFFD6317A),
    error: Color(0xFFED3241),
    success: Color(0xFF35A936),
    info: Color(0xFF1877F2),
    onPrimary: Color(0xFFFFFFFF),

    pollSelectedBg: Color(0xFFEEF0FF),
    pollSelectedBorder: Color(0xFF214389),
    pollUnselectedBorder: Color(0xFFD9D9D9),
    pollOptionTextSelected: Color(0xFF26224D),
    pollOptionTextUnselected: Color(0xFF555570),
    pollPercentageText: Color(0xFF7C8393),

    linkColor: Color(0xFF1877F2),
    mediaErrorBg: Color(0xFFD9D9D9),
    documentBg: Color(0xFFF3F3F3),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK SCHEME — derived from Figma mockup
  // ═══════════════════════════════════════════════════════════════════════════

  static const dark = AppColorScheme(
    panelBackground: Color(0xFF232323),
    scaffoldBg: Color(0xFF1A1A2E),
    cardSurface: Color(0xFF252540),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0B0),
    textDarkBlue: Color(0xFFFFFFFF),
    textMuted: Color(0xFF6E6E80),

    divider: Color(0xFF2E2E45),
    dividerThick: Color(0xFF2E2E45),
    border: Color(0xFF3A3A55),

    backButtonBg: Color(0xFF2E2E45),
    backButtonBorder: Color(0xFF3A3A55),
    backButtonIcon: Color(0xFFFFFFFF),

    actionCardFilled: Color(0xFF6C3ABA),
    actionCardOutlineBg: Color(0xFF252540),
    actionCardOutlineBorder: Color(0xFF555570),
    actionCardOutlineText: Color(0xFFFFFFFF),

    chevron: Color(0xFF555570),
    menuLabelText: Color(0xFFFFFFFF),

    navBg: Color(0xFF1A1A2E),
    navBorder: Color(0xFF2E2E45),
    navLabelSelected: Color(0xFFFFFFFF),
    navLabelUnselected: Color(0xFF6E6E80),

    iconDefault: Color(0xFFFFFFFF),
    iconDisabled: Color(0xFF555570),
    shadowColor: Color(0x00000000), // Shadows invisible in dark mode
    inputFill: Color(0xFF252540),
    placeholderBg: Color(0xFF252540),

    primary: Color(0xFF4C6FFF), // Lighter primary for dark mode
    accent: Color(0xFFE25494), // Lighter accent for dark mode
    error: Color(0xFFFF5252),
    success: Color(0xFF4CAF50),
    info: Color(0xFF448AFF),
    onPrimary: Color(0xFFFFFFFF),

    pollSelectedBg: Color(0xFF2E2E45),
    pollSelectedBorder: Color(0xFF4C6FFF),
    pollUnselectedBorder: Color(0xFF3A3A55),
    pollOptionTextSelected: Color(0xFFFFFFFF),
    pollOptionTextUnselected: Color(0xFFA0A0B0),
    pollPercentageText: Color(0xFF6E6E80),

    linkColor: Color(0xFF6FA8FF),
    mediaErrorBg: Color(0xFF2E2E45),
    documentBg: Color(0xFF252540),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME EXTENSION OVERRIDES
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  AppColorScheme copyWith({
    Color? panelBackground,
    Color? scaffoldBg,
    Color? cardSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDarkBlue,
    Color? textMuted,
    Color? divider,
    Color? dividerThick,
    Color? border,
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
    Color? iconDefault,
    Color? iconDisabled,
    Color? shadowColor,
    Color? inputFill,
    Color? placeholderBg,
    Color? primary,
    Color? accent,
    Color? error,
    Color? success,
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
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDarkBlue: textDarkBlue ?? this.textDarkBlue,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      dividerThick: dividerThick ?? this.dividerThick,
      border: border ?? this.border,
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
      iconDefault: iconDefault ?? this.iconDefault,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      shadowColor: shadowColor ?? this.shadowColor,
      inputFill: inputFill ?? this.inputFill,
      placeholderBg: placeholderBg ?? this.placeholderBg,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      success: success ?? this.success,
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
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDarkBlue: Color.lerp(textDarkBlue, other.textDarkBlue, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      dividerThick: Color.lerp(dividerThick, other.dividerThick, t)!,
      border: Color.lerp(border, other.border, t)!,
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
      iconDefault: Color.lerp(iconDefault, other.iconDefault, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      placeholderBg: Color.lerp(placeholderBg, other.placeholderBg, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
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
