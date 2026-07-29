import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP THEME
/// Complete Material 3 ThemeData built from the Figma Color System.
///
/// Provides both Light and Dark themes with all component themes configured
/// to match the Figma palette exactly.
/// ──────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get light {
    return ThemeData(
      extensions: const [AppColorScheme.light],
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,

      // --- Color Scheme ---
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandNavy,          // #11428D
        onPrimary: AppColors.white,
        primaryContainer: AppColors.activeBg,   // #EEF2FF
        onPrimaryContainer: AppColors.brandNavy,
        secondary: AppColors.secondary,         // #4F46E5 Brand Indigo
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.activeBg, // #EEF2FF
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.purple,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.purpleSoft,
        onTertiaryContainer: AppColors.purple,
        error: AppColors.error,                 // #EF4444
        onError: AppColors.white,
        errorContainer: AppColors.dangerBg,     // #FEF2F2
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.surface,             // #FFFFFF
        onSurface: AppColors.textPrimary,       // #111827
        surfaceContainerHighest: AppColors.gray100, // #F3F4F6
        onSurfaceVariant: AppColors.textSecondary,  // #6B7280
        outline: AppColors.gray300,             // #D1D5DB
        outlineVariant: AppColors.gray200,      // #E5E7EB
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.secondaryLight, // #818CF8
      ),

      // --- Scaffold ---
      scaffoldBackgroundColor: AppColors.appBackground, // #F9FBFF

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.surface,      // white app bar
        foregroundColor: AppColors.textPrimary,   // #111827
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,        // white
        selectedItemColor: AppColors.activeText,    // #4F46E5 Brand Indigo
        unselectedItemColor: AppColors.textTertiary, // #9CA3AF
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.navLabel,
        unselectedLabelStyle: AppTypography.navLabel,
        showUnselectedLabels: true,
        selectedIconTheme: IconThemeData(size: AppSpacing.iconBase),
        unselectedIconTheme: IconThemeData(size: AppSpacing.iconBase),
      ),

      // --- Navigation Bar (Material 3) ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.activeBg,        // #EEF2FF
        height: AppSpacing.bottomNavHeight,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.activeText,          // #4F46E5
              size: AppSpacing.iconBase,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,          // #9CA3AF
            size: AppSpacing.iconBase,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(
              color: AppColors.activeText,
            );
          }
          return AppTypography.navLabel.copyWith(
            color: AppColors.textTertiary,
          );
        }),
      ),

      // --- Tab Bar ---
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandNavy,           // #11428D
        unselectedLabelColor: AppColors.textSecondary, // #6B7280
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.brandNavy,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.gray200,           // #E5E7EB
      ),

      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandNavy,    // #11428D
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 2,
          shadowColor: AppColors.primary40,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      // --- Filled Button ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandNavy,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.buttonLarge,
        ),
      ),

      // --- Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandNavy,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          side: const BorderSide(color: AppColors.brandNavy, width: 1.5),
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandNavy,
          disabledForegroundColor: AppColors.textTertiary,
          textStyle: AppTypography.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),

      // --- Icon Button ---
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,   // #111827
          disabledForegroundColor: AppColors.textTertiary,
        ),
      ),

      // --- Floating Action Button ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // --- Card ---
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppSpacing.cardElevation,
        shadowColor: AppColors.border,             // rgba(0,0,0,0.08)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.xs,
        ),
      ),

      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,            // #F3F4F6
        hintStyle: AppTypography.inputHint.copyWith(
          color: AppColors.textTertiary,           // #9CA3AF
        ),
        labelStyle: AppTypography.inputLabel.copyWith(
          color: AppColors.textSecondary,          // #6B7280
        ),
        errorStyle: AppTypography.inputError.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.brandNavy,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.activeBg,       // #EEF2FF
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.secondary,              // #4F46E5
        ),
        selectedColor: AppColors.brandNavy,
        disabledColor: AppColors.gray200,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      ),

      // --- Bottom Sheet ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        dragHandleColor: AppColors.chevron,         // #D1D5DB
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // --- Snack Bar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,        // #111827
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.secondaryLight, // #818CF8
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,                // #F3F4F6
        thickness: AppSpacing.dividerThickness,
        space: 0,
      ),

      // --- List Tile ---
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
        ),
        minVerticalPadding: AppSpacing.md,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        titleTextStyle: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTypography.caption.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.toggleOn;             // #22C55E
          }
          return AppColors.toggleOff;              // #D1D5DB
        }),
      ),

      // --- Checkbox ---
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandNavy;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.chevron, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // --- Radio ---
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandNavy;
          }
          return AppColors.chevron;
        }),
      ),

      // --- Slider ---
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.brandNavy,
        inactiveTrackColor: AppColors.gray300,
        thumbColor: AppColors.brandNavy,
        overlayColor: AppColors.primary20,
      ),

      // --- Progress Indicator ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandNavy,
        linearTrackColor: AppColors.gray200,
        circularTrackColor: AppColors.gray200,
      ),

      // --- Badge ---
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.error,          // #EF4444
        textColor: AppColors.white,
        textStyle: AppTypography.labelSmall,
      ),

      // --- Text Theme ---
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // --- Tooltip ---
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
      ),

      // --- Popup Menu ---
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // --- Drawer ---
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        elevation: 16,
      ),

      // --- Splash / Ink ---
      splashColor: AppColors.primary10,
      highlightColor: AppColors.primary10,

      // --- Scrollbar ---
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.chevron),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark {
    return ThemeData(
      extensions: const [AppColorScheme.dark],
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,

      // --- Color Scheme ---
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandIndigoDark,         // #818CF8
        onPrimary: AppColors.textPrimary,           // #111827
        primaryContainer: AppColors.activeBgDark,   // #1E1E2E
        onPrimaryContainer: AppColors.brandIndigoDark,
        secondary: AppColors.brandIndigoDark,       // #818CF8
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.surfaceRaisedDark, // #252529
        onSecondaryContainer: AppColors.brandIndigoDark,
        tertiary: AppColors.purpleLight,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: AppColors.purple,
        onTertiaryContainer: AppColors.purpleSoft,
        error: AppColors.error,                     // #EF4444 (same)
        onError: AppColors.white,
        errorContainer: AppColors.dangerBgDark,     // rgba(239,68,68,0.1)
        onErrorContainer: AppColors.errorLight,
        surface: AppColors.surfaceDark,             // #1E1E24
        onSurface: AppColors.textPrimaryDark,       // #FFFFFF
        surfaceContainerHighest: AppColors.surfaceRaisedDark, // #252529
        onSurfaceVariant: AppColors.textSecondaryDark,        // #8A8A9A
        outline: AppColors.chevronDark,             // #48484A
        outlineVariant: AppColors.separatorDark,    // #2A2A30
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray100,
        onInverseSurface: AppColors.gray900,
        inversePrimary: AppColors.brandNavy,
      ),

      // --- Scaffold ---
      scaffoldBackgroundColor: AppColors.appBackgroundDark, // #141418

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.appBackgroundDark, // #141418
        foregroundColor: AppColors.textPrimaryDark,   // #FFFFFF
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,       // #1E1E24
        selectedItemColor: AppColors.activeTextDark,   // #818CF8
        unselectedItemColor: AppColors.textTertiaryDark, // #555560
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.navLabel,
        unselectedLabelStyle: AppTypography.navLabel,
        showUnselectedLabels: true,
      ),

      // --- Navigation Bar (Material 3) ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,       // #1E1E24
        indicatorColor: AppColors.activeBgDark,       // #1E1E2E
        height: AppSpacing.bottomNavHeight,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.activeTextDark,         // #818CF8
              size: AppSpacing.iconBase,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiaryDark,        // #555560
            size: AppSpacing.iconBase,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(
              color: AppColors.activeTextDark,
            );
          }
          return AppTypography.navLabel.copyWith(
            color: AppColors.textTertiaryDark,
          );
        }),
      ),

      // --- Tab Bar ---
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimaryDark,        // #FFFFFF
        unselectedLabelColor: AppColors.textTertiaryDark, // #555560
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.brandIndigoDark,    // #818CF8
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.separatorDark,        // #2A2A30
      ),

      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandIndigoDark, // #818CF8
          foregroundColor: AppColors.textPrimary,     // #111827 dark on light button
          disabledBackgroundColor: AppColors.chevronDark,
          disabledForegroundColor: AppColors.textTertiaryDark,
          elevation: 2,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.buttonLarge,
        ),
      ),

      // --- Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandIndigoDark,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          side: const BorderSide(
            color: AppColors.brandIndigoDark,
            width: 1.5,
          ),
          textStyle: AppTypography.buttonLarge,
        ),
      ),

      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandIndigoDark,
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // --- Card ---
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,                // #1E1E24
        elevation: AppSpacing.cardElevation,
        shadowColor: const Color(0x29000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,          // #252529
        hintStyle: AppTypography.inputHint.copyWith(
          color: AppColors.textTertiaryDark,         // #555560
        ),
        labelStyle: AppTypography.inputLabel.copyWith(
          color: AppColors.textSecondaryDark,        // #8A8A9A
        ),
        errorStyle: AppTypography.inputError.copyWith(
          color: AppColors.errorLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.chevronDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.chevronDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.brandIndigoDark,        // #818CF8
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
      ),

      // --- Bottom Sheet ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        dragHandleColor: AppColors.chevronDark,      // #48484A
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaisedDark, // #252529
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // --- Snack Bar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaisedDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        actionTextColor: AppColors.brandIndigoDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.separatorDark,              // #2A2A30
        thickness: AppSpacing.dividerThickness,
        space: 0,
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaisedDark, // #252529
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.brandIndigoDark,           // #818CF8
        ),
        selectedColor: AppColors.activeBgDark,
        disabledColor: AppColors.chevronDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide.none,
      ),

      // --- Floating Action Button ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // --- Text Theme ---
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiaryDark,
        ),
      ),

      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.textSecondaryDark;        // #8A8A9A
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.toggleOn;               // #22C55E
          }
          return AppColors.toggleOffDark;            // #3A3A3E
        }),
      ),

      // --- Splash / Ink ---
      splashColor: AppColors.primary20,
      highlightColor: AppColors.primary20,

      // --- Progress Indicator ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandIndigoDark,            // #818CF8
        linearTrackColor: AppColors.separatorDark,
        circularTrackColor: AppColors.separatorDark,
      ),

      // --- Badge ---
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        textStyle: AppTypography.labelSmall,
      ),
    );
  }
}
