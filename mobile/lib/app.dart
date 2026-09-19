import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:device_preview/device_preview.dart';

import 'core/localization/l10n_extension.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/settings/accessibility_provider.dart';
import 'l10n/gen/app_localizations.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/widgets/no_connection_overlay.dart';
import 'features/auth/presentation/auth_providers.dart';

import 'features/call/presentation/widgets/incoming_call_overlay.dart'; // adjust path to your actual file location

class ZennytApp extends ConsumerWidget {
  const ZennytApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final a11y = ref.watch(accessibilityProvider);
    final router = ref.watch(goRouterProvider);

    ref.watch(webSocketConnectionProvider);

    // Native UI par plateforme : CupertinoApp (Liquid Glass sur iOS 26+) sur
    // iOS, MaterialApp sur Android.
    return AdaptiveApp.router(
      builder: (context, child) {
        // Sur iOS, AdaptiveApp construit une CupertinoApp qui n'installe pas de
        // Theme Material : on le réinstalle pour que `context.colors`, les
        // Scaffold et le mode sombre des écrans existants restent corrects.
        final themed = PlatformInfo.isIOS
            ? Theme(
                data: _isDark(context, themeMode)
                    ? AppTheme.dark
                    : AppTheme.light,
                child: child ?? const SizedBox.shrink(),
              )
            : child;
        final previewChild = DevicePreview.appBuilder(context, themed);
        final scaledChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: a11y.textScaler(MediaQuery.textScalerOf(context)),
          ),
          child: previewChild,
        );
        return DefaultTextStyle(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.none,
          ),
          child: NoConnectionOverlay(
            child: IncomingCallOverlay(child: scaledChild),
          ),
        );
      },
      onGenerateTitle: (context) => context.l10n.appName,
      locale: DevicePreview.locale(context) ?? locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      materialLightTheme: AppTheme.light,
      materialDarkTheme: AppTheme.dark,
      cupertinoLightTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.brandNavy,
        scaffoldBackgroundColor: AppColors.appBackground,
      ),
      cupertinoDarkTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.brandIndigoDark,
        scaffoldBackgroundColor: AppColors.appBackgroundDark,
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  static bool _isDark(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };
}
