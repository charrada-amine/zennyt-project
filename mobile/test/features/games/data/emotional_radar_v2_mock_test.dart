import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_v2_config.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_v2_referential.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar_v2.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/repositories/emotional_radar_v2_repository.dart';

/// Budget de réponse lu dans la config plutôt que recopié : le nombre en dur
/// faisait échouer ces tests à chaque ajustement — c'est arrivé au passage de
/// 8 s à 30 s.
const _maxMs = EmotionalRadarV2Config.maxResponseTimeMs;

void main() {
  late GamesMockRepository games;
  late EmotionalRadarV2Repository radar;
  late String sessionId;

  setUp(() async {
    games = GamesMockRepository();
    radar = games;
    sessionId = (await games.startSession(GameType.emotionalRegulation)).id;
  });

  test('referential flags sensitive content explicitly', () {
    expect(emotionByKey('JOY')!.sensitiveContentFlag, isFalse);
    expect(emotionByKey('SEXUAL_DESIRE')!.sensitiveContentFlag, isTrue);
  });

  test('game score rejects an empty session like the Java service', () {
    expect(() => radarEmotionScore(0, 0, 1), throwsArgumentError);
  });

  test('starts with a server-shaped L1 state and six choices', () async {
    final snapshot = await radar.emotionalRadarV2State(sessionId);
    expect(snapshot.currentScene, isNull);

    final state = await radar.activateNextEmotionalRadarV2Scene(sessionId);

    expect(state.totalScenes, 15);
    expect(state.currentLevel, 1);
    expect(state.currentScene!.choicesCount, 6);
    expect(state.currentScene!.choices, hasLength(6));
    expect(state.mediaLibraryReady, isFalse);
    expect(state.measurementAvailable, isFalse);
    expect(state.scoringProvisional, isTrue);
    expect(state.fitScorePublished, isFalse);
  });

  test('accepts an empty explanation, rejects a replay', () async {
    final state = await radar.activateNextEmotionalRadarV2Scene(sessionId);
    final scene = state.currentScene!;
    final correct = scene.choices.firstWhere((choice) => choice.key == 'SADNESS');

    // La troisième question a été retirée de l'écran : celui-ci envoie
    // désormais une justification vide. Le mock doit l'accepter, sans quoi
    // aucune manche ne passerait hors ligne.
    await radar.answerEmotionalRadarV2Scene(
      sessionId: sessionId,
      sceneOrder: scene.sceneOrder,
      selectedEmotionKey: correct.key,
      selectedIntensity: EmotionalRadarV2Intensity.low,
      explanation: '',
    );

    // Le verrou de rejeu, lui, ne bouge pas : une scène déjà répondue reste
    // close.
    expect(
      () => radar.answerEmotionalRadarV2Scene(
        sessionId: sessionId,
        sceneOrder: scene.sceneOrder,
        selectedEmotionKey: correct.key,
        selectedIntensity: EmotionalRadarV2Intensity.low,
        explanation: 'Replay attempt.',
      ),
      throwsStateError,
    );
  });

  test('GET is pure and POST next idempotently activates N+1', () async {
    final initial = await radar.activateNextEmotionalRadarV2Scene(sessionId);
    final scene = initial.currentScene!;
    final result = await radar.answerEmotionalRadarV2Scene(
      sessionId: sessionId,
      sceneOrder: scene.sceneOrder,
      selectedEmotionKey: scene.choices.first.key,
      selectedIntensity: EmotionalRadarV2Intensity.low,
      explanation: 'Visible cues.',
    );

    expect(result.state.completed, isFalse);
    expect(result.state.currentScene, isNull);

    final snapshot = await radar.emotionalRadarV2State(sessionId);
    expect(snapshot.currentScene, isNull);

    final next = await radar.activateNextEmotionalRadarV2Scene(sessionId);
    expect(next.currentScene!.sceneOrder, 2);
    expect(
      next.currentScene!.remainingResponseTimeMs,
      inInclusiveRange(_maxMs - 100, _maxMs),
    );
    final samePending = await radar.activateNextEmotionalRadarV2Scene(
      sessionId,
    );
    expect(samePending.currentScene!.sceneOrder, 2);
  });

  test(
    'mock monotonic clock matches impulsive and timeout boundaries',
    () async {
      for (final elapsedMs in [399, 400, _maxMs, _maxMs + 1]) {
        var nowMs = 0;
        final timedGames = GamesMockRepository(
          emotionalRadarV2ClockMs: () => nowMs,
        );
        final timedSessionId = (await timedGames.startSession(
          GameType.emotionalRegulation,
        )).id;
        final scene = (await timedGames.activateNextEmotionalRadarV2Scene(
          timedSessionId,
        )).currentScene!;
        nowMs = elapsedMs;

        final feedback = (await timedGames.answerEmotionalRadarV2Scene(
          sessionId: timedSessionId,
          sceneOrder: scene.sceneOrder,
          selectedEmotionKey: 'SADNESS',
          selectedIntensity: EmotionalRadarV2Intensity.low,
          explanation: 'Visible cues.',
        )).feedback;

        expect(feedback.impulsive, elapsedMs < 400, reason: '$elapsedMs ms');
        expect(feedback.timedOut, elapsedMs > _maxMs, reason: '$elapsedMs ms');
        expect(
          feedback.responseTimeMs,
          elapsedMs.clamp(0, _maxMs),
          reason: '$elapsedMs ms',
        );
      }
    },
  );

  test('three correct answers move the repository-owned level to L2', () async {
    var state = await radar.activateNextEmotionalRadarV2Scene(sessionId);
    for (var scene = 0; scene < 3; scene++) {
      final current = state.currentScene!;
      final expectedKey = ['SADNESS', 'ANXIETY', 'LONELINESS'][scene];
      final choice = current.choices.firstWhere(
        (candidate) => candidate.key == expectedKey,
      );
      state = (await radar.answerEmotionalRadarV2Scene(
        sessionId: sessionId,
        sceneOrder: current.sceneOrder,
        selectedEmotionKey: choice.key,
        selectedIntensity: EmotionalRadarV2Intensity.values[scene],
        explanation: 'Visible cues for $expectedKey.',
      )).state;
      if (!state.completed) {
        state = await radar.activateNextEmotionalRadarV2Scene(sessionId);
      }
    }

    expect(state.currentLevel, 2);
    expect(state.currentScene!.choicesCount, 6);
  });

  test(
    'complete run returns /10 report while fit publication stays false',
    () async {
      var state = await radar.activateNextEmotionalRadarV2Scene(sessionId);
      var lastServedLevel = state.currentScene!.level;
      while (!state.completed) {
        final scene = state.currentScene!;
        lastServedLevel = scene.level;
        // The mock catalogue progresses through the referential in scene order.
        final expected = scene.choices.firstWhere(
          (choice) => choice.key == _expectedKeys[scene.sceneOrder - 1],
        );
        state = (await radar.answerEmotionalRadarV2Scene(
          sessionId: sessionId,
          sceneOrder: scene.sceneOrder,
          selectedEmotionKey: expected.key,
          selectedIntensity:
              EmotionalRadarV2Intensity.values[(scene.sceneOrder - 1) % 3],
          explanation: 'Observable cues.',
        )).state;
        if (!state.completed) {
          state = await radar.activateNextEmotionalRadarV2Scene(sessionId);
        }
      }

      expect(state.report, isNotNull);
      expect(state.report!.totalScenes, 15);
      expect(state.report!.radarEmotionScore, inInclusiveRange(0, 10));
      expect(state.report!.accuracyByChoiceCount.keys, containsAll([6, 9]));
      expect(state.report!.justificationScoringAvailable, isFalse);
      expect(state.report!.semanticDistanceScoringAvailable, isFalse);
      expect(state.report!.accuracyBySemanticDistance, isEmpty);
      expect(state.report!.stimulusTypeScoringAvailable, isFalse);
      expect(state.report!.stimulusTypePerformance, isEmpty);
      expect(state.fitScorePublished, isFalse);
      // Backend parity: finalLevel is scene 15's served level, not a
      // hypothetical adaptive level after the final response.
      expect(state.report!.finalLevel, lastServedLevel);
      expect(state.currentLevel, lastServedLevel);
    },
  );
}

// DÉMO : les trois émotions filmées ouvrent la session (voir
// `_radarV2ExpectedKeys` et `DEMO_FOOTAGE_ORDER`).
const _expectedKeys = [
  'SADNESS',
  'ANXIETY',
  'LONELINESS',
  'JOY',
  'AMUSEMENT',
  'SATISFACTION',
  'INTEREST',
  'SURPRISE',
  'ANGER',
  'FEAR',
  'DISGUST',
  'HORROR',
  'CONTEMPT',
  'DISAPPOINTMENT',
  'PAIN',
];
