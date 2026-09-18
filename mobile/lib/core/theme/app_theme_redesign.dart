import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_typography.dart';
import '../../shared/icons/app_icons.dart';

/// The September visual refresh, shared by both themes and all Material controls.
/// Existing feature-specific semantics and color overrides remain supported.
ThemeData applyExperienceTheme(ThemeData base) {
  final dark = base.brightness == Brightness.dark;
  final colors = dark ? AppColorScheme.dark : AppColorScheme.light;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: colors.border),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  final actionStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 54)),
    shape: WidgetStatePropertyAll(shape),
    elevation: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed) ? 0 : 2,
    ),
    shadowColor: WidgetStatePropertyAll(colors.primary.withValues(alpha: .16)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    textStyle: const WidgetStatePropertyAll(AppTypography.buttonLarge),
    animationDuration: AppMotion.settle,
  );
  return base.copyWith(
    // Boutons implicites (retour, fermeture, tiroirs) en HugeIcons.
    actionIconTheme: appActionIconTheme,
    scaffoldBackgroundColor: colors.scaffoldBg,
    colorScheme: base.colorScheme.copyWith(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primary.withValues(alpha: .10),
      onPrimaryContainer: colors.textDarkBlue,
      secondary: colors.accent,
      onSecondary: Colors.white,
      secondaryContainer: colors.accent.withValues(alpha: .10),
      onSecondaryContainer: colors.textDarkBlue,
      surface: colors.cardSurface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.divider,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colors.scaffoldBg,
      foregroundColor: colors.textDarkBlue,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleSpacing: 24,
      toolbarHeight: 68,
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: colors.textDarkBlue,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.merge(actionStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.merge(actionStyle),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.merge(
        actionStyle.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: colors.textDarkBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: colors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 1.6),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textMuted),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: colors.textSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: colors.textDarkBlue,
      ),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: colors.cardSurface,
      modalBackgroundColor: colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      dragHandleColor: colors.border,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.inputFill,
      selectedColor: colors.primary.withValues(alpha: .12),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: colors.textDarkBlue,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      iconColor: colors.primary,
      titleTextStyle: AppTypography.titleSmall.copyWith(
        color: colors.textDarkBlue,
      ),
      subtitleTextStyle: AppTypography.bodySmall.copyWith(
        color: colors.textSecondary,
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: colors.primary,
      unselectedLabelColor: colors.textSecondary,
      dividerColor: Colors.transparent,
      indicatorColor: colors.accent,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: AppColors.primaryDeep,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerTheme: DividerThemeData(
      color: colors.divider,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: colors.accent,
      linearTrackColor: colors.inputFill,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
