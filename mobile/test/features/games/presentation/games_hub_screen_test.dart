import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/view/games_hub_screen.dart';

Future<void> _pumpHub(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const GamesHubScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category cards and game picker show the available game logos', (
    tester,
  ) async {
    await _pumpHub(tester);

    void expectAssetLogo(String key, String assetName) {
      final logo = find.byKey(ValueKey(key));
      expect(logo, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: logo, matching: find.byType(Image)),
      );
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, assetName);
    }

    expect(
      find.byKey(const ValueKey('category-game-logo-Move Fast')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Move Fast',
      'assets/games icons/Move Fast.png',
    );
    expectAssetLogo(
      'category-game-logo-Je continue',
      'assets/games icons/Je Continue.png',
    );
    expectAssetLogo(
      'category-game-logo-Je coordonne',
      'assets/games icons/Je Coordonne.png',
    );
    expect(find.text('2–25 min'), findsOneWidget);
    expect(find.text('3 games'), findsOneWidget);

    final flexibilityCard = find.byKey(
      const ValueKey('game-category-cognitive-flexibility'),
    );
    await tester.tap(flexibilityCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('picker-game-logo-Move Fast')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Je continue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Je coordonne')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-game-logo-Memory Quest')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Memory Quest',
      'assets/games icons/Memory Quest transparent.png',
    );

    final decisionCard = find.byKey(
      const ValueKey('game-category-decision-making'),
    );
    await tester.scrollUntilVisible(
      decisionCard,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expectAssetLogo(
      'category-game-logo-Je Décide',
      'assets/games icons/Je Decide transparent.png',
    );

    final planningCard = find.byKey(
      const ValueKey('game-category-executive-planning'),
    );
    await tester.scrollUntilVisible(
      planningCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-game-logo-Optimal Path')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Optimal Path',
      'assets/games icons/Optimal Path transparent.png',
    );
    expect(
      find.byKey(const ValueKey('category-game-logo-Task Scheduling')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Task Scheduling',
      'assets/games icons/Task Scheduling transparent.png',
    );
    expect(
      find.byKey(const ValueKey('category-game-logo-Predictive Puzzle')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Predictive Puzzle',
      'assets/games icons/Predictive Puzzle transparent.png',
    );

    final emotionCard = find.byKey(
      const ValueKey('game-category-emotional-regulation'),
    );
    await tester.scrollUntilVisible(
      emotionCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expectAssetLogo(
      'category-game-logo-Emotional Radar',
      'assets/games icons/Emotional Radar.png',
    );
    expectAssetLogo(
      'category-game-logo-Reflective Pause',
      'assets/games icons/Reflective Pause.png',
    );

    await tester.tap(planningCard);
    await tester.pumpAndSettle();

    expect(find.text('Choose a game to play'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('picker-game-logo-Optimal Path')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Optimal Path',
      'assets/games icons/Optimal Path transparent.png',
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Task Scheduling')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Task Scheduling',
      'assets/games icons/Task Scheduling transparent.png',
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Predictive Puzzle')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Predictive Puzzle',
      'assets/games icons/Predictive Puzzle transparent.png',
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(emotionCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('picker-game-logo-Emotional Radar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Reflective Pause')),
      findsOneWidget,
    );
  });

  for (final textScale in [1.3, 2.0]) {
    testWidgets(
      '390x844 textScale $textScale keeps hub and flexibility picker usable',
      (tester) async {
        await _pumpHub(tester, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.bySemanticsLabel('Back'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('category-game-logo-Move Fast')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('category-game-logo-Je continue')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('category-game-logo-Je coordonne')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('game-category-cognitive-flexibility')),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('picker-game-logo-Move Fast')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('picker-game-logo-Je continue')),
          findsOneWidget,
        );
        final coordinationPickerLogo = find.byKey(
          const ValueKey('picker-game-logo-Je coordonne'),
        );
        await tester.scrollUntilVisible(
          coordinationPickerLogo,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(coordinationPickerLogo, findsOneWidget);
      },
    );
  }
}
