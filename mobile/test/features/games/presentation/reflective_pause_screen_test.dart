import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/reflective_pause_screen.dart';

void main() {
  Future<void> pumpGame(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: ReflectivePauseScreen(now: tester.binding.clock.now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reachGameplay(WidgetTester tester) async {
    await tester.tap(find.text('Start mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start mission'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets('la couverture et le tutoriel suivent les maquettes', (
    tester,
  ) async {
    await pumpGame(tester);

    expect(find.text('Reflective Pause'), findsWidgets);
    expect(find.text('Impulse Control'), findsWidgets);
    expect(find.text('View tutorial'), findsOneWidget);
    expect(find.text('Start mission'), findsOneWidget);

    await tester.tap(find.text('View tutorial'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Train calm responses'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Think'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Respond'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Respond'), findsOneWidget);
  });

  testWidgets('le timer bloque les choix et le menu pause reprend le chrono', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    expect(find.text('Moment 1 / 10'), findsOneWidget);
    expect(find.textContaining('Pause for'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Input mode'), findsOneWidget);
    expect(find.text('View rules / Help'), findsOneWidget);
    expect(find.text('Exit mission'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    expect(
      find.text('Take the response that feels most natural.'),
      findsOneWidget,
    );

    final choice = find.text('Breathe and analyze');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
    final validate = find.text('Validate response');
    await tester.ensureVisible(validate);
    await tester.tap(validate);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(find.text('Moment 2 / 10'), findsOneWidget);
  });

  testWidgets('les dix moments aboutissent au score serveur et aux insights', (
    tester,
  ) async {
    await pumpGame(tester);
    await reachGameplay(tester);

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump();
      final choice = find.text('Breathe and analyze');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      final validate = find.text('Validate response');
      await tester.ensureVisible(validate);
      await tester.tap(validate);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Results preview'), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('Controlled reaction time'), findsOneWidget);
    expect(find.text('Non-impulsive responses'), findsOneWidget);
    expect(find.text('Ability to step back'), findsOneWidget);

    await tester.tap(find.text('View learning insights'));
    await tester.pumpAndSettle();
    expect(find.text('Learning insights'), findsOneWidget);
    expect(find.text('Strongest area'), findsOneWidget);
    expect(find.text('Impulsivity risk'), findsOneWidget);
    expect(find.text('Pressure pattern'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });
}
