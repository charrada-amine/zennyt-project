import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/reflective_pause_config.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_metrics.dart';

/// Parité mock ⇄ backend du barème « Reflective Pause ».
///
/// Miroir de `ReflectivePauseScoringTest` (Java).
void main() {
  late GamesMockRepository repo;

  setUp(() => repo = GamesMockRepository());

  const recommended = <ReflectivePauseResponseType>[
    ReflectivePauseResponseType.breatheAnalyze,
    ReflectivePauseResponseType.askForMoreInformation,
    ReflectivePauseResponseType.wait,
    ReflectivePauseResponseType.askForMoreInformation,
    ReflectivePauseResponseType.breatheAnalyze,
    ReflectivePauseResponseType.reformulateCalmly,
    ReflectivePauseResponseType.wait,
    ReflectivePauseResponseType.reformulateCalmly,
    ReflectivePauseResponseType.breatheAnalyze,
    ReflectivePauseResponseType.askForMoreInformation,
  ];

  ReflectivePauseMetrics perfectMetrics() {
    return ReflectivePauseMetrics(
      moments: [
        for (var i = 0; i < ReflectivePauseConfig.totalMoments; i++)
          ReflectivePauseMomentMetric(
            momentId: 'PRESSURE_${(i + 1).toString().padLeft(2, '0')}',
            selectedResponse: recommended[i],
            responseTimeMs: 3500,
            minimumTimerReached: true,
          ),
      ],
    );
  }

  test('10 pauses et réponses recommandées donnent 10/10', () async {
    final initial = await repo.startSession(GameType.emotionalRegulation);
    final result = await repo.submitResult(
      sessionId: initial.id,
      miniGame: MiniGame.reflectivePauseCore,
      metrics: perfectMetrics(),
    );

    expect(result.lastAttempt?.score.rawPoints, 10);
    expect(result.lastAttempt?.score.maxPoints, 10);
    expect(result.lastAttempt?.score.level, 'Very good self-control');
    expect(result.status, 'IN_PROGRESS');
    expect(result.compositeMax, 10);
    expect(result.reflectivePauseIndicators?.controlledReactionTimeScore, 3);
    expect(result.reflectivePauseIndicators?.nonImpulsiveResponsesScore, 4);
    expect(result.reflectivePauseIndicators?.abilityToStepBackScore, 3);
    expect(result.scoreBreakdown, isNotEmpty);
  });

  test(
    '8 pauses, 9 non-impulsives et 7 prises de recul donnent 8/10',
    () async {
      final initial = await repo.startSession(GameType.emotionalRegulation);
      final moments = <ReflectivePauseMomentMetric>[];
      for (var i = 0; i < ReflectivePauseConfig.totalMoments; i++) {
        final timerReached = i < 8;
        final response = switch (i) {
          7 => ReflectivePauseResponseType.respondImpulsively,
          8 || 9 => ReflectivePauseResponseType.wait,
          _ => recommended[i],
        };
        moments.add(
          ReflectivePauseMomentMetric(
            momentId: 'PRESSURE_${(i + 1).toString().padLeft(2, '0')}',
            selectedResponse: response,
            responseTimeMs: timerReached ? 3200 : 2500,
            minimumTimerReached: timerReached,
          ),
        );
      }

      final result = await repo.submitResult(
        sessionId: initial.id,
        miniGame: MiniGame.reflectivePauseCore,
        metrics: ReflectivePauseMetrics(moments: moments),
      );

      expect(result.lastAttempt?.score.rawPoints, 8);
      final report = result.reflectivePauseIndicators!;
      expect(report.controlledReactionTimeScore, 2.4);
      expect(report.nonImpulsiveResponsesScore, 3.6);
      expect(report.abilityToStepBackScore, 2.1);
    },
  );

  test('le booléen timer incohérent avec le temps est refusé', () async {
    final initial = await repo.startSession(GameType.emotionalRegulation);
    final metrics = perfectMetrics();
    final forged = ReflectivePauseMetrics(
      moments: [
        ReflectivePauseMomentMetric(
          momentId: metrics.moments.first.momentId,
          selectedResponse: metrics.moments.first.selectedResponse,
          responseTimeMs: 1200,
          minimumTimerReached: true,
        ),
        ...metrics.moments.skip(1),
      ],
    );

    expect(
      () => repo.submitResult(
        sessionId: initial.id,
        miniGame: MiniGame.reflectivePauseCore,
        metrics: forged,
      ),
      throwsArgumentError,
    );
  });

  test(
    'Emotional Radar puis Reflective Pause complètent le composite /37',
    () async {
      final initial = await repo.startSession(GameType.emotionalRegulation);
      final scenes = await repo.emotionalRadarScenes(initial.id);
      const answers = [
        (BasicEmotion.sadness, 'DISAPPOINTMENT', 3),
        (BasicEmotion.fear, 'ANXIETY', 4),
        (BasicEmotion.sadness, 'EMPATHIC_PAIN', 3),
      ];
      final radarMetrics = <EmotionalRadarSceneMetric>[];
      for (var i = 0; i < scenes.scenes.length; i++) {
        final answer = answers[i];
        await repo.answerEmotionalRadarScene(
          sessionId: initial.id,
          sceneId: scenes.scenes[i].id,
          emotion: answer.$1,
          nuanceKey: answer.$2,
          intensity: answer.$3,
        );
        radarMetrics.add(
          EmotionalRadarSceneMetric(
            sceneId: scenes.scenes[i].id,
            responseTimeMs: 5000,
          ),
        );
      }
      final afterRadar = await repo.submitResult(
        sessionId: initial.id,
        miniGame: MiniGame.emotionalRadarCore,
        metrics: EmotionalRadarMetrics(scenes: radarMetrics),
      );
      expect(afterRadar.status, 'IN_PROGRESS');
      expect(afterRadar.compositeMax, 37);

      final completed = await repo.submitResult(
        sessionId: initial.id,
        miniGame: MiniGame.reflectivePauseCore,
        metrics: perfectMetrics(),
      );
      expect(completed.status, 'COMPLETED');
      expect(completed.compositeRaw, 37);
      expect(completed.compositeMax, 37);
      expect(completed.normalized, 100);
    },
  );
}
