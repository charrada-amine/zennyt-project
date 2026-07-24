import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/view/games_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category cards and game picker show the available game logos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: GamesHubScreen())),
    );
    await tester.pumpAndSettle();

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
    expect(
      find.byKey(const ValueKey('category-game-logo-Memory Quest')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Memory Quest',
      'assets/games icons/Memory Quest.png',
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
      'assets/games icons/Je Decide.png',
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
      'assets/games icons/Optimal Path.png',
    );
    expect(
      find.byKey(const ValueKey('category-game-logo-Task Scheduling')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Task Scheduling',
      'assets/games icons/Task Scheduling.png',
    );
    expect(
      find.byKey(const ValueKey('category-game-logo-Predictive Puzzle')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Predictive Puzzle',
      'assets/games icons/Predictive Puzzle.png',
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
      'assets/games icons/Optimal Path.png',
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Task Scheduling')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Task Scheduling',
      'assets/games icons/Task Scheduling.png',
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Predictive Puzzle')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Predictive Puzzle',
      'assets/games icons/Predictive Puzzle.png',
    );
  });
}
