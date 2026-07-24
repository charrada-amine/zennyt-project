import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_screen.dart';
import 'package:zennyt/features/navigation/presentation/widgets/app_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'phase 1 enters phase 2, keeps choices neutral and hides bottom nav',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: JeDecideScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Decision Journey'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('welcome-start')));

      for (var page = 0; page < 3; page++) {
        await tapVisible(tester, find.byKey(const ValueKey('onboarding-next')));
      }

      expect(find.text('Create your player card'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('player-continue')));

      expect(find.text('Choose your avatar'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('avatar-continue')));

      expect(find.text('Practice round'), findsWidgets);
      await tapVisible(tester, find.byKey(const ValueKey('practice-start')));

      expect(find.text('Choosing a route'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      final continueFinder = find.descendant(
        of: find.byKey(const ValueKey('practice-continue')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);

      await tapVisible(tester, find.byKey(const ValueKey('choice-faster')));

      expect(tester.widget<FilledButton>(continueFinder).onPressed, isNotNull);
      expect(find.textContaining('correct'), findsNothing);
      expect(find.textContaining('wrong'), findsNothing);

      await tapVisible(tester, find.byKey(const ValueKey('practice-continue')));

      expect(find.text('Delivery Bike'), findsOneWidget);
      expect(find.text('Scenario 04 / 30'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    },
  );
}
