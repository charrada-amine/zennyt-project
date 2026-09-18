import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zennyt/core/storage/shared_preferences_provider.dart';
import 'package:zennyt/features/games/domain/entities/games_progress.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/games_hub_screen.dart';

Future<void> _pumpHub(
  WidgetTester tester, {
  double textScale = 1,
  GamesProgress? progress,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Pre-agree to the monitoring consent (design 76) so tapping a card opens the
  // game picker directly, not the consent dialog.
  SharedPreferences.setMockInitialValues({'games_monitoring_consent': true});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gamesProgressProvider.overrideWith((ref) async => progress),
      ],
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

    final flexibilityCard = find.byKey(
      const ValueKey('game-category-cognitive-flexibility'),
    );
    // Portée à la carte visée : « 3 jeux » n'est pas unique dans le hub —
    // plusieurs catégories comptent trois jeux. L'assertion globale ne tenait
    // que parce que la police de remplacement des tests, plus large que la
    // vraie, empêchait la seconde carte de se peindre.
    expect(
      find.descendant(of: flexibilityCard, matching: find.text('3 jeux')),
      findsOneWidget,
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
      find.byKey(const ValueKey('category-game-logo-Memory Quest · Digits')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Memory Quest · Digits',
      'assets/games icons/Memory Quest transparent.png',
    );
    expectAssetLogo(
      'category-game-logo-Je place',
      'assets/games icons/Je Place.png',
    );

    final memoryCard = find.byKey(
      const ValueKey('game-category-working-memory'),
    );
    await tester.tap(memoryCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('picker-game-logo-Memory Quest · Digits')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Je place',
      'assets/games icons/Je Place.png',
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

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
      'assets/games icons/Optimal Path menu original.png',
    );
    void expectOriginalMenuLogo(String key) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
        reason: 'logo original sans pastille mauve',
      );
    }

    expectOriginalMenuLogo('category-game-logo-Optimal Path');
    await tester.tap(
      find.byKey(const ValueKey('game-category-executive-planning')),
    );
    await tester.pumpAndSettle();
    expectAssetLogo(
      'picker-game-logo-Optimal Path',
      'assets/games icons/Optimal Path menu original.png',
    );
    expectOriginalMenuLogo('picker-game-logo-Optimal Path');
    final picker = find.byType(BottomSheet);
    for (final image in tester.widgetList<Image>(
      find.descendant(of: picker, matching: find.byType(Image)),
    )) {
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(picker)),
      );
    }
    await tester.pumpAndSettle();
    await expectLater(
      picker,
      matchesGoldenFile('goldens/optimal-path-logo-white-background.png'),
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-game-logo-Day Stack')),
      findsOneWidget,
    );
    expectAssetLogo(
      'category-game-logo-Day Stack',
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
    expectAssetLogo(
      'category-game-logo-Strategic Choices',
      'assets/games icons/Strategic Choices.png',
    );

    await tester.tap(planningCard);
    await tester.pumpAndSettle();

    expect(find.text('Choisis un jeu'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('picker-game-logo-Optimal Path')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Optimal Path',
      'assets/games icons/Optimal Path menu original.png',
    );
    expect(
      find.byKey(const ValueKey('picker-game-logo-Day Stack')),
      findsOneWidget,
    );
    expectAssetLogo(
      'picker-game-logo-Day Stack',
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

    // Emotional Regulation : ses trois jeux sont ouverts, la carte présente
    // donc le sélecteur avec les trois logos.
    await tester.tap(emotionCard);
    await tester.pumpAndSettle();
    expect(find.text('Choisis un jeu'), findsOneWidget);
    for (final logo in const [
      ('Emotional Radar', 'assets/games icons/Emotional Radar.png'),
      ('Reflective Pause', 'assets/games icons/Reflective Pause.png'),
      ('Strategic Choices', 'assets/games icons/Strategic Choices.png'),
    ]) {
      expect(
        find.byKey(ValueKey('picker-game-logo-${logo.$1}')),
        findsOneWidget,
      );
      expectAssetLogo('picker-game-logo-${logo.$1}', logo.$2);
    }
  });

  for (final textScale in [1.3, 2.0]) {
    testWidgets(
      '390x844 textScale $textScale keeps hub and flexibility picker usable',
      (tester) async {
        await _pumpHub(tester, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Retour'), findsOneWidget);
        expect(find.bySemanticsLabel('Retour'), findsOneWidget);
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

  test('le nombre de jeux accorde « jeu » au singulier', () {
    expect(gameCountLabel(1), '1 jeu');
    expect(gameCountLabel(3), '3 jeux');
  });

  testWidgets('chaque catégorie affiche son nombre réel de jeux, en français', (
    tester,
  ) async {
    await _pumpHub(tester);

    // Radar émotionnel, planification et décision affichaient « N° aptitudes »
    // faute de libellé explicite : le compte vient désormais de la liste.
    for (final (key, title) in const [
      ('game-category-cognitive-flexibility', 'Flexibilité cognitive'),
      ('game-category-working-memory', 'Mémoire de travail'),
      ('game-category-decision-making', 'Prise de décision'),
      ('game-category-executive-planning', 'Planification exécutive'),
      ('game-category-emotional-regulation', 'Régulation émotionnelle'),
    ]) {
      final card = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: card, matching: find.text(title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('3 jeux')),
        findsOneWidget,
        reason: key,
      );
    }
    expect(find.textContaining('aptitudes'), findsNothing);
  });

  testWidgets('une catégorie n’est terminée que si tous ses jeux le sont', (
    tester,
  ) async {
    Finder check(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byIcon(Icons.check_circle_rounded),
    );

    // Deux jeux sur trois de Régulation émotionnelle : pas encore terminée.
    await _pumpHub(
      tester,
      progress: const GamesProgress(
        completed: {CatalogGame.emotionalRadar, CatalogGame.reflectivePause},
      ),
    );
    final card = find.byKey(
      const ValueKey('game-category-emotional-regulation'),
    );
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(check('game-category-emotional-regulation'), findsNothing);
  });

  testWidgets('tous les jeux jouables terminés : la catégorie l’est aussi', (
    tester,
  ) async {
    Finder check(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byIcon(Icons.check_circle_rounded),
    );

    // Move Fast suffit pour Flexibilité cognitive : ses deux autres jeux sont
    // fermés (« Bientôt ») et ne peuvent pas être terminés.
    await _pumpHub(
      tester,
      progress: const GamesProgress(
        completed: {
          CatalogGame.emotionalRadar,
          CatalogGame.reflectivePause,
          CatalogGame.strategicChoices,
          CatalogGame.moveFast,
        },
      ),
    );
    expect(check('game-category-cognitive-flexibility'), findsOneWidget);
    expect(check('game-category-working-memory'), findsNothing);
    final card = find.byKey(
      const ValueKey('game-category-emotional-regulation'),
    );
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(check('game-category-emotional-regulation'), findsOneWidget);
  });

  testWidgets('la couverture affiche la part des jeux terminés', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      progress: const GamesProgress(
        completed: {
          CatalogGame.moveFast,
          CatalogGame.decision,
          CatalogGame.taskScheduling,
        },
      ),
    );
    expect(find.text('Couverture 20 %'), findsOneWidget, reason: '3 / 15');
    expect(find.text('Couverture 0 %'), findsNothing);
  });

  testWidgets('progression inconnue : un tiret, pas un faux 0 %', (
    tester,
  ) async {
    await _pumpHub(tester);
    expect(find.text('Couverture —'), findsOneWidget);
  });
}
