import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_config.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

/// Parité mock ⇄ backend du barème « Emotional Radar ».
///
/// Miroir de `EmotionalRadarScoringTest` (Java) : les mêmes cas doivent donner
/// les mêmes points des deux côtés.
void main() {
  late GamesMockRepository repo;

  setUp(() => repo = GamesMockRepository());

  Future<(String, EmotionalRadarSceneSet)> startGame() async {
    final session = await repo.startSession(GameType.emotionalRegulation);
    final scenes = await repo.emotionalRadarScenes(session.id);
    return (session.id, scenes);
  }

  test('le barème vaut 3 + 4 + 2 = 9 points par scène', () {
    expect(EmotionalRadarConfig.emotionPoints, 3);
    expect(EmotionalRadarConfig.nuancePoints, 4);
    expect(EmotionalRadarConfig.intensityPoints, 2);
    expect(EmotionalRadarConfig.pointsPerScene, 9);
    // Les deux totaux annoncés par la maquette.
    expect(EmotionalRadarConfig.maxPointsFor(3), 27);
    expect(EmotionalRadarConfig.maxPointsFor(15), 135);
  });

  test('le bonus de gradient reste désactivé', () {
    // L'activer porterait une scène à 10 points et casserait 27 et 135.
    expect(EmotionalRadarConfig.gradientBonusEnabled, isFalse);
  });

  test('les scènes servies ne contiennent aucune réponse attendue', () async {
    final (_, sceneSet) = await startGame();

    expect(sceneSet.scenes, isNotEmpty);
    // Le type `EmotionalRadarScene` n'expose volontairement aucun champ
    // `expected*` : la correction ne peut pas être faite côté client.
    final scene = sceneSet.scenes.first;
    expect(scene.promptText, isNotEmpty);
    expect(scene.instructionText, isNotEmpty);
    expect(sceneSet.totalScenes, 3);
  });

  test('réponse parfaite sur la scène 1 → 9 points', () async {
    final (sessionId, sceneSet) = await startGame();
    final scene = sceneSet.scenes.first;

    final feedback = await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.sadness,
      nuanceKey: 'DISAPPOINTMENT',
      intensity: 3,
    );

    expect(feedback.correct, isTrue);
    expect(feedback.emotionPoints, 3);
    expect(feedback.nuancePoints, 4);
    expect(feedback.intensityPoints, 2);
    expect(feedback.scenePoints, 9);
    expect(feedback.totalPoints, 9);
  });

  test('mauvaise famille → émotion et nuance à 0, intensité évaluée à part', () async {
    final (sessionId, sceneSet) = await startGame();
    final scene = sceneSet.scenes.first;

    final feedback = await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.joy,
      nuanceKey: 'EXCITEMENT',
      intensity: 3, // intensité juste malgré la mauvaise famille
    );

    expect(feedback.correct, isFalse);
    expect(feedback.emotionPoints, 0);
    expect(feedback.nuancePoints, 0);
    expect(feedback.intensityPoints, 2);
    expect(feedback.scenePoints, 2);
    // La correction n'est révélée qu'ici.
    expect(feedback.expectedEmotion, BasicEmotion.sadness);
    expect(feedback.expectedNuance, 'DISAPPOINTMENT');
  });

  test('intensité : écart 1 → 1 pt, écart ≥ 2 → 0', () async {
    final (sessionId, sceneSet) = await startGame();
    final scene = sceneSet.scenes.first; // intensité attendue : 3

    final near = await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.sadness,
      nuanceKey: 'DISAPPOINTMENT',
      intensity: 4,
    );
    expect(near.intensityPoints, 1);

    final far = await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.sadness,
      nuanceKey: 'DISAPPOINTMENT',
      intensity: 1,
    );
    expect(far.intensityPoints, 0);
  });

  test('re-valider une scène remplace la réponse au lieu de doubler les points',
      () async {
    final (sessionId, sceneSet) = await startGame();
    final scene = sceneSet.scenes.first;

    await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.sadness,
      nuanceKey: 'DISAPPOINTMENT',
      intensity: 3,
    );
    final second = await repo.answerEmotionalRadarScene(
      sessionId: sessionId,
      sceneId: scene.id,
      emotion: BasicEmotion.sadness,
      nuanceKey: 'DISAPPOINTMENT',
      intensity: 3,
    );

    expect(second.answeredScenes, 1);
    expect(second.totalPoints, 9); // et non 18
  });

  test('partie complète : 3 scènes parfaites → 27/27 et un détail du score',
      () async {
    final (sessionId, sceneSet) = await startGame();

    // Les 3 réponses attendues (miroir du seed V25).
    const answers = [
      (BasicEmotion.sadness, 'DISAPPOINTMENT', 3),
      (BasicEmotion.fear, 'ANXIETY', 4),
      (BasicEmotion.sadness, 'EMPATHIC_PAIN', 3),
    ];

    final metrics = <EmotionalRadarSceneMetric>[];
    for (var i = 0; i < sceneSet.scenes.length; i++) {
      final scene = sceneSet.scenes[i];
      final (emotion, nuance, intensity) = answers[i];
      await repo.answerEmotionalRadarScene(
        sessionId: sessionId,
        sceneId: scene.id,
        emotion: emotion,
        nuanceKey: nuance,
        intensity: intensity,
      );
      metrics.add(
        EmotionalRadarSceneMetric(sceneId: scene.id, responseTimeMs: 5000),
      );
    }

    final session = await repo.submitResult(
      sessionId: sessionId,
      miniGame: MiniGame.emotionalRadarCore,
      metrics: EmotionalRadarMetrics(scenes: metrics),
    );

    final attempt = session.attempts.last;
    expect(attempt.miniGame, MiniGame.emotionalRadarCore);
    expect(attempt.score.rawPoints, 27);
    expect(attempt.score.maxPoints, 27);
    expect(attempt.score.level, 'Excellent');
    expect(session.scoreBreakdown, isNotEmpty);
  });

  test('soumettre sans avoir validé de scène est refusé', () async {
    final session = await repo.startSession(GameType.emotionalRegulation);

    expect(
      () => repo.submitResult(
        sessionId: session.id,
        miniGame: MiniGame.emotionalRadarCore,
        metrics: const EmotionalRadarMetrics(
          scenes: [
            EmotionalRadarSceneMetric(sceneId: 'forged', responseTimeMs: 1),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test('les nuances Figma et provisoires sont distinguées', () async {
    final (_, sceneSet) = await startGame();

    // SADNESS vient intégralement de la maquette.
    final sadness = sceneSet.nuancesFor(BasicEmotion.sadness);
    expect(sadness.map((n) => n.label), [
      'Disappointment',
      'Nostalgia',
      'Empathic pain',
      'Sympathy',
      'Guilt',
    ]);
    expect(sadness.every((n) => n.source == NuanceSource.figma), isTrue);

    // ANGER n'apparaît sur aucune planche : tout y est provisoire.
    final anger = sceneSet.nuancesFor(BasicEmotion.anger);
    expect(anger, isNotEmpty);
    expect(anger.every((n) => n.source == NuanceSource.provisional), isTrue);

    // Les six familles de la grille sont couvertes.
    expect(sceneSet.emotions.length, 6);
  });
}
