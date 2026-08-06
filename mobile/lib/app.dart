import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:device_preview/device_preview.dart';

import 'core/localization/l10n_extension.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
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
    final router = ref.watch(goRouterProvider);

    ref.watch(webSocketConnectionProvider);

    return MaterialApp.router(
      builder: (context, child) {
        final previewChild = DevicePreview.appBuilder(context, child);
        return NoConnectionOverlay(
          child: IncomingCallOverlay(child: previewChild!),
        );
      },
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context) ?? locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}