import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_results.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// Profil tel qu'il arrive du serveur : SCW /100, niveau, et détail /18 par
  /// dimension. CS et RE sont marquées provisoires — c'est l'état réel du barème.
  DecisionProfile profileFixture({int score = 71}) => DecisionProfile(
    score: score,
    level: 'Normal',
    dimensions: [
      DecisionDimensionResult(
        code: 'ER',
        label: 'Risk Balance',
        shortLabel: 'Risk',
        description: 'How you weigh outcomes.',
        points: 11,
        maxPoints: 18,
        provisional: false,
      ),
      DecisionDimensionResult(
        code: 'DT',
        label: 'Quick Choice',
        shortLabel: 'Quick',
        description: 'How you decide under time pressure.',
        points: 15,
        maxPoints: 18,
        provisional: false,
      ),
      DecisionDimensionResult(
        code: 'CS',
        label: 'Decision Stability',
        shortLabel: 'Stability',
        description: 'How stable your choices stay.',
        points: 12,
        maxPoints: 18,
        provisional: true,
      ),
      DecisionDimensionResult(
        code: 'RE',
        label: 'Self-Control',
        shortLabel: 'Control',
        description: 'How you weigh delayed rewards.',
        points: 12,
        maxPoints: 18,
        provisional: true,
      ),
    ],
  );

  Widget subject({
    DecisionResultsStep initialStep = DecisionResultsStep.journeyComplete,
    VoidCallback? onDone,
    int score = 71,
  }) {
    return MaterialApp(
      home: DecisionResultsFlow(
        answered: 22,
        totalItems: 24,
        profile: profileFixture(score: score),
        initialStep: initialStep,
        onClose: () {},
        onDone: onDone ?? () {},
      ),
    );
  }

  testWidgets('phase 4 runs from completion to detailed profile and export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var done = false;

    await tester.pumpWidget(subject(onDone: () => done = true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('decision-journey-complete')),
      findsOneWidget,
    );
    // La carte annonçait « 24 / 24 » en dur : un sans-faute affiché même quand
    // des questions avaient expiré. Elle compte maintenant les réponses réelles
    // — ici 22 sur 24.
    expect(find.text('22 / 24'), findsOneWidget);
    expect(find.text('24 / 24'), findsNothing);
    await tap(tester, 'decision-reveal-profile');

    expect(
      find.byKey(const ValueKey('decision-preparing-profile')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('decision-profile-title')),
      findsOneWidget,
    );
    expect(find.text('Normal'), findsOneWidget, reason: 'niveau serveur');
    // Le score s'anime de 0 → 71 (compteur animé) : laisser l'animation finir.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('71%'), findsOneWidget);
    await tap(tester, 'decision-view-insights');

    expect(find.text('Analytical Thinking'), findsNothing);
    expect(find.text('Risk Balance'), findsOneWidget);
    expect(find.text('Self-Control'), findsOneWidget);
    await tap(tester, 'decision-export-summary');

    expect(find.byKey(const ValueKey('decision-export-share')), findsOneWidget);
    expect(find.text('Your individual choices stay private.'), findsOneWidget);
    await tap(tester, 'decision-results-done');
    expect(done, isTrue);
  });

  testWidgets('un score serveur réellement nul reste un résultat valide', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(initialStep: DecisionResultsStep.profile, score: 0),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    expect(
      find.byKey(const ValueKey('decision-profile-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('decision-profile-score')),
      findsOneWidget,
    );
    expect(find.text('0%'), findsOneWidget);
    expect(
      find.text('0 / 100 points calculated by the server.'),
      findsOneWidget,
    );
  });

  testWidgets('radar exposes every public dimension as text semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Le radar vit sur l'écran de détail : l'écran de score suit le modèle
    // commun, sans graphique.
    await tester.pumpWidget(subject(initialStep: DecisionResultsStep.details));
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Risk Balance 61 out of 100, '
        'Quick Choice 83 out of 100, Decision Stability 67 out of 100, '
        'Self-Control 67 out of 100',
      ),
      findsOneWidget,
    );
  });
}
