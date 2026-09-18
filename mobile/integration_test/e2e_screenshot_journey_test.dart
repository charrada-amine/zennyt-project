import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_nav_item.dart';
import 'package:zennyt/main.dart' as app;
import 'package:zennyt/shared/widgets/primary_button.dart';

/// Full UI journey against the live backend, capturing a screenshot per screen.
///
/// Run (simulator booted, backend on :8080):
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/e2e_screenshot_journey_test.dart -d DEVICE_ID
///
/// Locale-agnostic (the app may run in FR): taps by widget type/position, not by
/// label. Missing targets are skipped so the run still yields screenshots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'ui-e2e@example.test';
  const password = 'Password123';

  Future<void> shot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } catch (e) {
      debugPrint('E2E: screenshot "$name" failed: $e');
    }
  }

  Future<bool> waitFor(WidgetTester tester, Finder finder, {int seconds = 25}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) return;
    await tester.tap(finder.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Drains framework exceptions (e.g. the known duplicate-Hero assertion thrown
  /// when a Cupertino nav bar route is pushed) so the journey can continue.
  void drain(WidgetTester tester) {
    var guard = 0;
    while (tester.takeException() != null && guard++ < 20) {}
  }

  testWidgets('candidate journey', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 1));
    await shot('01_splash');

    // Onboarding: tap the primary "Next"/"Get started" button until login shows.
    for (var i = 0; i < 8; i++) {
      if (find.byType(TextField).evaluate().isNotEmpty) break;
      final cta = find.byType(PrimaryButton);
      if (cta.evaluate().isEmpty) {
        await waitFor(tester, find.byType(PrimaryButton), seconds: 6);
      }
      if (find.byType(PrimaryButton).evaluate().isEmpty) break;
      await tap(tester, find.byType(PrimaryButton));
      await shot('02_onboarding_${i + 1}');
    }

    // Login (unless the app is already signed in from a previous run).
    if (find.byType(AppNavItem).evaluate().isEmpty) {
      if (!await waitFor(tester, find.byType(TextField), seconds: 15)) {
        debugPrint('E2E: login fields never appeared');
        await shot('03_login_missing');
        return;
      }
      await shot('03_login');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), password);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await shot('04_login_filled');
      await tap(tester, find.byType(PrimaryButton));
    }

    // Home / bottom navigation.
    if (!await waitFor(tester, find.byType(AppNavItem), seconds: 25)) {
      debugPrint('E2E: bottom nav never appeared (login may have failed)');
      await shot('05_home_missing');
      return;
    }
    await shot('05_home');

    final tabs = ['06_fits', '07_progress', '08_search', '09_notifications'];
    for (var i = 0; i < tabs.length; i++) {
      final items = find.byType(AppNavItem);
      if (items.evaluate().length <= i + 1) break;
      await tester.tap(items.at(i + 1));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      drain(tester);
      await shot(tabs[i]);
    }

    // Remaining screens: navigate through the app's own GoRouter (reliable,
    // locale-independent), screenshot each, then pop back.
    try {
      final ctx = tester.element(find.byType(AppNavItem).first);
      final router = GoRouter.of(ctx);
      final routes = <String, String>{
        '10_profile_settings': AppRoutes.profileSettings,
        '11_wallet': AppRoutes.wallet,
        '12_referral': AppRoutes.referral,
        '13_plans': AppRoutes.plans,
        '14_terms': AppRoutes.termsOfUse,
        '15_language': AppRoutes.languageSettings,
        '16_accessibility': AppRoutes.accessibility,
        '17_hired_candidates': AppRoutes.hiredCandidates,
      };
      for (final entry in routes.entries) {
        router.go(entry.value);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        drain(tester);
        await shot(entry.key);
      }
    } catch (e) {
      debugPrint('E2E: profile section stopped: $e');
      await shot('18_profile_section_error');
    }
  });
}
