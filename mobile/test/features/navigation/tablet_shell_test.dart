import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/domain/entities/app_user.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/navigation/presentation/widgets/adaptive_nav_shell.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_side_nav.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_bottom_nav.dart';
import 'package:zennyt/features/navigation/presentation/viewmodel/nav_tab_provider.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required double dpr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => AdaptiveNavShell(
          pages: List.generate(5, (_) => const _PlaceholderPage()),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(
          const AppUser(
            id: 'u',
            firstName: 'Test',
            lastName: 'User',
            email: 'test@example.test',
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  testWidgets('phone width keeps bottom nav and no sidebar', (tester) async {
    await _pumpShell(tester, size: const Size(390, 844), dpr: 1);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppSideNav), findsNothing);
  });

  testWidgets(
      'tablet width shows persistent rail sidebar instead of bottom nav',
      (tester) async {
    await _pumpShell(tester, size: const Size(1536, 2048), dpr: 2);

    expect(find.byType(AppSideNav), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(
      tester.getSize(find.byType(AppSideNav)).width,
      AppSideNav.railWidth,
    );
  });

  testWidgets('sidebar becomes expanded on desktop widths', (tester) async {
    await _pumpShell(tester, size: const Size(1440, 900), dpr: 1);

    expect(
      tester.getSize(find.byType(AppSideNav)).width,
      AppSideNav.expandedWidth,
    );
  });

  testWidgets('tapping a side-nav destination switches the visible page',
      (tester) async {
    await _pumpShell(tester, size: const Size(1440, 900), dpr: 1);

    // Five placeholder pages are identical, so switch on the IndexedStack
    // index the provider drives.
    final context = tester.element(find.byType(AdaptiveNavShell));
    final container = ProviderScope.containerOf(context);
    expect(container.read(navTabProvider), 0);

    await tester.tap(find.text('Notifications').last);
    await tester.pumpAndSettle();

    expect(container.read(navTabProvider), 4);
  });
}
