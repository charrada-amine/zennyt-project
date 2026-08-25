import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_screen.dart';

/// Parcours complet d'« Emotional Radar » sur une taille d'écran de maquette.
void main() {
  Future<void> pumpGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(GamesMockRepository()),
        ],
        child: const MaterialApp(home: EmotionalRadarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Cover → tutoriel → première scène.
  Future<void> startPlaying(WidgetTester tester) async {
    await tester.tap(find.text('Start tutorial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
  }

  testWidgets('la couverture présente le jeu et mène au tutoriel', (tester) async {
    await pumpGame(tester);

    expect(find.text('Emotional Radar'), findsWidgets);
    expect(find.text('Recognize emotions in real situations.'), findsOneWidget);
    expect(find.text('Start tutorial'), findsOneWidget);
    expect(find.text('View rules'), findsOneWidget);

    await tester.tap(find.text('View rules'));
    await tester.pumpAndSettle();

    // Les cinq étapes de la maquette.
    expect(find.text('Rules and tutorial'), findsOneWidget);
    expect(find.text('Observe the scene.'), findsOneWidget);
    expect(find.text('Validate your answer.'), findsOneWidget);
  });

  testWidgets('révélation progressive : nuance et intensité restent verrouillées',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    // Scène 1 affichée, avec son en-tête.
    expect(find.text('Scene 1 / 3'), findsOneWidget);
    expect(find.text('Score 0'), findsOneWidget);
    expect(find.textContaining('I have to cancel tonight'), findsOneWidget);

    // Étapes 2 et 3 verrouillées tant qu'aucune émotion n'est choisie.
    expect(find.text('Locked'), findsNWidgets(2));
    expect(find.text('Select an emotion first.'), findsOneWidget);
    expect(find.text('Choose a nuance first.'), findsOneWidget);

    // Choisir une émotion déverrouille l'étape 2, pas l'étape 3.
    await tester.tap(find.text('Sadness'));
    await tester.pumpAndSettle();

    expect(find.text('Disappointment'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Choose a nuance first.'), findsOneWidget);

    // Choisir la nuance déverrouille l'intensité.
    await tester.tap(find.text('Disappointment'));
    await tester.pumpAndSettle();

    expect(find.text('Locked'), findsNothing);
    expect(find.text('Choose one level'), findsOneWidget);
  });

  testWidgets('Validate reste inactif tant que les trois choix ne sont pas faits',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    ElevatedButton validateButton() => tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Validate my answer'),
            matching: find.byType(ElevatedButton),
          ),
        );

    expect(validateButton().onPressed, isNull);

    await tester.tap(find.text('Sadness'));
    await tester.pumpAndSettle();
    expect(validateButton().onPressed, isNull);

    await tester.tap(find.text('Disappointment'));
    await tester.pumpAndSettle();
    expect(validateButton().onPressed, isNull);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    // Les trois choix sont faits : le bouton s'active.
    expect(validateButton().onPressed, isNotNull);
  });

  testWidgets('bonne réponse : feedback correct et score mis à jour immédiatement',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    await tester.tap(find.text('Sadness'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disappointment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validate my answer'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
    expect(
      find.text('You identified the emotional pattern accurately.'),
      findsOneWidget,
    );
    expect(find.text('Expected emotion'), findsOneWidget);
    expect(find.textContaining('unmet expectation'), findsOneWidget);

    // Le score passe à 9 DÈS la carte de feedback (correction de maquette).
    expect(find.text('Score 9'), findsOneWidget);
    expect(find.text('Next scene'), findsOneWidget);
  });

  testWidgets('mauvaise réponse : la meilleure réponse est montrée avec son intensité',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    await tester.tap(find.text('Joy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excitement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validate my answer'));
    await tester.pumpAndSettle();

    expect(find.text('Good try - here is the best answer'), findsOneWidget);
    expect(find.text('Your answer'), findsOneWidget);
    expect(find.text('Joy / Excitement / 2'), findsOneWidget);
    // Correction de maquette : « Best answer » porte aussi l'intensité.
    expect(find.text('Best answer'), findsOneWidget);
    expect(find.text('Sadness / Disappointment / 3'), findsOneWidget);
  });

  testWidgets("l'aide rappelle les cinq étapes sans quitter la partie",
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    await tester.tap(find.text('? Help'));
    await tester.pumpAndSettle();

    expect(find.text('Need a reminder?'), findsOneWidget);
    expect(
      find.text('There is no penalty for reading the instructions again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Resume game'));
    await tester.pumpAndSettle();

    // Retour au gameplay, sélection intacte.
    expect(find.text('Scene 1 / 3'), findsOneWidget);
  });

  testWidgets('le menu pause propose mode d\'entrée, audio, règles et sortie',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();

    expect(find.text('Pause'), findsWidgets);
    expect(find.text('Input mode'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
    expect(find.text('Tactile'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Exit mission'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Scene 1 / 3'), findsOneWidget);
  });

  testWidgets('partie complète : 3 scènes parfaites → 27/27, sans détail du barème',
      (tester) async {
    await pumpGame(tester);
    await startPlaying(tester);

    // Les 3 réponses attendues (miroir du seed V25).
    const answers = [
      ('Sadness', 'Disappointment', '3'),
      ('Fear', 'Anxiety', '4'),
      ('Sadness', 'Empathic pain', '3'),
    ];

    // Les cartes s'allongent au fil des étapes : chaque cible doit être
    // ramenée dans le viewport avant d'être touchée.
    Future<void> tapText(String label) async {
      final finder = find.text(label);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    for (var i = 0; i < answers.length; i++) {
      final (emotion, nuance, intensity) = answers[i];

      await tapText(emotion);
      await tapText(nuance);
      await tapText(intensity);
      await tapText('Validate my answer');

      expect(find.text('Correct!'), findsOneWidget);

      final isLast = i == answers.length - 1;
      await tapText(isLast ? 'See my results' : 'Next scene');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Écran de résultats : score serveur (ici mock), SANS le détail du barème.
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('27 / 27'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('3 scenes completed'), findsOneWidget);
    // Le détail de la formule de calcul du score a été retiré de l'affichage
    // sur retour client — il reste calculé côté serveur.
    expect(find.text('Score detail'), findsNothing);
  });
}
