import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/enums/user_role.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/core/localization/locale_controller.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/auth/domain/entities/app_user.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import 'package:zennyt/features/profile_settings/presentation/view/profile_settings_screen.dart';
import 'package:zennyt/features/profile_settings/presentation/view/language_settings_screen.dart';
import 'package:zennyt/features/profile_settings/presentation/widgets/language_option_tile.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

class _Auth extends AuthController {
  _Auth(this.role);
  final UserRole role;
  @override
  Future<AppUser?> build() async => AppUser(
    id: 'preview',
    firstName: 'Alexandra',
    lastName: 'Ben Salem',
    email: 'alexandra@example.test',
    role: role,
  );
}

Future<SharedPreferences> _pump(
  WidgetTester tester,
  Widget screen, {
  UserRole role = UserRole.candidate,
  bool dark = false,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            RepaintBoundary(key: const Key('preview'), child: screen),
      ),
      GoRoute(
        path: '/profile',
        name: 'userProfile',
        builder: (_, _) => const Scaffold(body: Text('Opened profile')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => _Auth(role)),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: dark ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (Platform.environment['WRITE_REDESIGN_PREVIEWS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../output/redesign/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('Settings ${dark ? 'dark' : 'light'} opens the profile', (
      tester,
    ) async {
      await _pump(tester, const ProfileSettingsScreen(), dark: dark);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'profile-settings-${dark ? 'dark' : 'light'}');
      await tester.tap(find.text('Alexandra Ben Salem'));
      await tester.pumpAndSettle();
      expect(find.text('Opened profile'), findsOneWidget);
    });
  }
  testWidgets('Recruiter settings support narrow screens and enlarged text', (
    tester,
  ) async {
    await _pump(
      tester,
      const ProfileSettingsScreen(),
      role: UserRole.recruiter,
      width: 320,
      scale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Log out'), 250);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('Language changes immediately and persists its selection', (
    tester,
  ) async {
    final prefs = await _pump(
      tester,
      const LanguageSettingsScreen(),
      width: 320,
      scale: 1.5,
    );
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(prefs.getString('locale_code'), 'fr');
    expect(find.text('Langue'), findsOneWidget);
    final option = tester.widget<LanguageOptionTile>(
      find.widgetWithText(LanguageOptionTile, 'Français'),
    );
    expect(option.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
