import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// APP THEME
/// Complete Material 3 ThemeData built from the Figma Design (Design.jpg)
///
/// Provides both Light and Dark themes with all component themes configured
/// to match the design system exactly.
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
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.secondaryLighter,
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.purple,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.purpleSoft,
        onTertiaryContainer: AppColors.purple,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorSoft,
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.surface,
        onSurface: AppColors.gray900,
        surfaceContainerHighest: AppColors.gray100,
        onSurfaceVariant: AppColors.gray600,
        outline: AppColors.gray300,
        outlineVariant: AppColors.gray200,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.secondaryLight,
      ),

      // --- Scaffold ---
      scaffoldBackgroundColor: AppColors.background,

      // --- AppBar ---
      // Note: we intentionally do NOT set iconTheme / actionsIconTheme here.
      // Letting foregroundColor drive both the title text and icons keeps a
      // single source of truth so screens that override foregroundColor for a
      // light/transparent AppBar (e.g. dark back arrow on white) work as
      // expected without each one having to repeat the iconTheme override.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.white,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarActive,
        unselectedItemColor: AppColors.navBarInactive,
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
        backgroundColor: AppColors.navBarBackground,
        indicatorColor: AppColors.primary40,
        height: AppSpacing.bottomNavHeight,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.navBarActive,
              size: AppSpacing.iconBase,
            );
          }
          return const IconThemeData(
            color: AppColors.navBarInactive,
            size: AppSpacing.iconBase,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(
              color: AppColors.navBarActive,
            );
          }
          return AppTypography.navLabel.copyWith(
            color: AppColors.navBarInactive,
          );
        }),
      ),

      // --- Tab Bar ---
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.gray500,
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.gray200,
      ),

      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray500,
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray500,
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
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.gray400,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
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
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.gray400,
          textStyle: AppTypography.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),

      // --- Icon Button ---
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.gray900,
          disabledForegroundColor: AppColors.gray400,
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
        shadowColor: const Color(0x14000000),
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
        fillColor: AppColors.gray100,
        hintStyle: AppTypography.inputHint.copyWith(color: AppColors.gray500),
        labelStyle: AppTypography.inputLabel.copyWith(color: AppColors.gray600),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
        backgroundColor: AppColors.tagBackground,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.tagText,
        ),
        selectedColor: AppColors.primary,
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        dragHandleColor: AppColors.gray400,
        dragHandleSize: Size(40, 4),
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
          color: AppColors.gray900,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),

      // --- Snack Bar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSlate,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.secondaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
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
          color: AppColors.gray900,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.gray600,
        ),
        leadingAndTrailingTextStyle: AppTypography.caption.copyWith(
          color: AppColors.gray500,
        ),
      ),

      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.gray300;
        }),
      ),

      // --- Checkbox ---
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.gray400, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // --- Radio ---
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.gray400;
        }),
      ),

      // --- Slider ---
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.gray300,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary20,
      ),

      // --- Progress Indicator ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.gray200,
        circularTrackColor: AppColors.gray200,
      ),

      // --- Badge ---
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.badge,
        textColor: AppColors.white,
        textStyle: AppTypography.labelSmall,
      ),

      // --- Text Theme ---
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.gray900,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.gray900,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.gray900,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.gray900,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.gray900,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.gray900,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.gray900),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.gray900,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.gray900),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.gray900),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.gray900),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.gray600),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.gray900),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.gray600,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.gray500),
      ),

      // --- Tooltip ---
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSlate,
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
        textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.gray900),
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
        thumbColor: WidgetStateProperty.all(AppColors.gray400),
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
        primary: AppColors.secondaryLight,
        onPrimary: AppColors.gray900,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.gray900,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.secondaryLighter,
        tertiary: AppColors.purpleLight,
        onTertiary: AppColors.gray900,
        tertiaryContainer: AppColors.purple,
        onTertiaryContainer: AppColors.purpleSoft,
        error: AppColors.errorLight,
        onError: AppColors.gray900,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.errorSoft,
        surface: AppColors.darkSurface,
        onSurface: AppColors.gray50,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.gray400,
        outline: AppColors.gray700,
        outlineVariant: AppColors.darkSlate,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray100,
        onInverseSurface: AppColors.gray900,
        inversePrimary: AppColors.primary,
      ),

      // --- Scaffold ---
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: AppColors.white,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.white,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.navLabel,
        unselectedLabelStyle: AppTypography.navLabel,
        showUnselectedLabels: true,
      ),

      // --- Navigation Bar (Material 3) ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary40,
        height: AppSpacing.bottomNavHeight,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.white,
              size: AppSpacing.iconBase,
            );
          }
          return const IconThemeData(
            color: AppColors.gray500,
            size: AppSpacing.iconBase,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(color: AppColors.white);
          }
          return AppTypography.navLabel.copyWith(color: AppColors.gray500);
        }),
      ),

      // --- Tab Bar ---
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray500,
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.secondaryLight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.gray700,
      ),

      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryLight,
          foregroundColor: AppColors.gray900,
          disabledBackgroundColor: AppColors.gray700,
          disabledForegroundColor: AppColors.gray500,
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
          foregroundColor: AppColors.secondaryLight,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          side: const BorderSide(color: AppColors.secondaryLight, width: 1.5),
          textStyle: AppTypography.buttonLarge,
        ),
      ),

      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // --- Card ---
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppSpacing.cardElevation,
        shadowColor: const Color(0x29000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        hintStyle: AppTypography.inputHint.copyWith(color: AppColors.gray500),
        labelStyle: AppTypography.inputLabel.copyWith(color: AppColors.gray400),
        errorStyle: AppTypography.inputError.copyWith(
          color: AppColors.errorLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gray700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.gray700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.secondaryLight,
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
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        dragHandleColor: AppColors.gray600,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.gray400,
        ),
      ),

      // --- Snack Bar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray100,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.gray900,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.gray700,
        thickness: AppSpacing.dividerThickness,
        space: 0,
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.secondaryLight,
        ),
        selectedColor: AppColors.primary,
        disabledColor: AppColors.gray700,
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
          color: AppColors.white,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.white,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.white,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.white,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.white,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.white),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.white),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.white),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.gray50),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.gray50),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.gray400),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.gray50),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.gray400,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.gray500),
      ),

      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryLight;
          }
          return AppColors.gray500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.gray700;
        }),
      ),

      // --- Splash / Ink ---
      splashColor: AppColors.primary20,
      highlightColor: AppColors.primary20,

      // --- Progress Indicator ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryLight,
        linearTrackColor: AppColors.gray700,
        circularTrackColor: AppColors.gray700,
      ),

      // --- Badge ---
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.badge,
        textColor: AppColors.white,
        textStyle: AppTypography.labelSmall,
      ),
    );
  }
}
