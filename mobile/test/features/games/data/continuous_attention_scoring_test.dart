import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/continuous_attention_scoring.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/continuous_attention_config.dart';
import 'package:zennyt/features/games/domain/entities/continuous_attention_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

void main() {
  const scoring = ContinuousAttentionScoring();
  const sessionId = '00000000-0000-4000-8000-000000000001';

  test('score parfait = 100, pratique exclue et indicateurs descriptifs', () {
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isPractice ? false : target,
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.score.rawPoints, 100);
    expect(result.score.maxPoints, 100);
    expect(result.indicators.sessionValid, isTrue);
    expect(result.indicators.xPhase.targetCount, 160);
    expect(result.indicators.xPhase.nonTargetCount, 460);
    expect(result.indicators.axPhase.targetCount, 120);
    expect(result.indicators.axPhase.nonTargetCount, 500);
    expect(result.indicators.xPhase.hitCount, 160);
    expect(result.indicators.axPhase.hitCount, 120);
    expect(result.indicators.epochs, hasLength(8));
    expect(result.indicators.axTargetCount, 120);
    expect(result.indicators.xPhase.dPrime.isFinite, isTrue);
    expect(result.indicators.axPhase.responseBiasC.isFinite, isTrue);
  });

  test('réussir ou manquer la pratique ne change jamais le score', () {
    final missedPractice = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(
        sessionId,
        shouldRespond: (phase, target, _) => phase.isTest && target,
      ),
    );
    final perfectPractice = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(sessionId, shouldRespond: (phase, target, _) => target),
    );

    expect(perfectPractice.score.rawPoints, missedPractice.score.rawPoints);
    expect(
      perfectPractice.indicators.xPhase.balancedAccuracyPercent,
      missedPractice.indicators.xPhase.balancedAccuracyPercent,
    );
    expect(
      perfectPractice.indicators.axPhase.balancedAccuracyPercent,
      missedPractice.indicators.axPhase.balancedAccuracyPercent,
    );
  });

  test('balanced accuracy est la seule composante du score', () {
    var xTargetIndex = 0;
    var xNonTargetIndex = 0;
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) {
        if (phase == ContinuousAttentionPhase.xTest) {
          if (target) return xTargetIndex++ < 80; // sensitivity X = 50 %
          return xNonTargetIndex++ < 46; // specificity X = 90 %
        }
        if (phase == ContinuousAttentionPhase.axTest) return target;
        return false;
      },
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.indicators.xPhase.hitRatePercent, closeTo(50, 1e-9));
    expect(
      result.indicators.xPhase.correctRejectionRatePercent,
      closeTo(90, 1e-9),
    );
    expect(result.indicators.xPhase.balancedAccuracyPercent, closeTo(70, 1e-9));
    expect(result.indicators.axPhase.balancedAccuracyPercent, 100);
    expect(result.score.rawPoints, 85);
  });

  test('vecteur QA score 84, d-prime et biais c', () {
    var xTarget = 0;
    var xNonTarget = 0;
    var axTarget = 0;
    var axNonTarget = 0;
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) {
        if (phase == ContinuousAttentionPhase.xTest) {
          return target ? xTarget++ < 120 : xNonTarget++ < 46;
        }
        if (phase == ContinuousAttentionPhase.axTest) {
          return target ? axTarget++ < 108 : axNonTarget++ < 100;
        }
        return false;
      },
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.score.rawPoints, 84);
    expect(result.indicators.xPhase.balancedAccuracyPercent, 82.5);
    expect(result.indicators.axPhase.balancedAccuracyPercent, 85);
    expect(result.indicators.xPhase.dPrime, closeTo(1.9462343855, 1e-8));
    expect(result.indicators.xPhase.responseBiasC, closeTo(0.3035058635, 1e-8));
    expect(result.indicators.axPhase.dPrime, closeTo(2.1024219831, 1e-8));
    expect(
      result.indicators.axPhase.responseBiasC,
      closeTo(-0.2117267076, 1e-8),
    );
  });

  test('timing > tolérance invalide la session sans changer le score', () {
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isTest && target,
      displayDurationOverride: (block, trial) => block == 2 && trial == 3
          ? ContinuousAttentionConfig.stimulusDurationMs +
                ContinuousAttentionConfig.timingToleranceMs +
                1
          : null,
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.score.rawPoints, 100);
    expect(result.indicators.sessionValid, isFalse);
    expect(result.indicators.timingDeviationCount, 1);
    expect(result.indicators.validityIssues, contains('TIMING_DEVIATION'));
  });

  test('écart de timing exactement 100 ms reste valide', () {
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isTest && target,
      displayDurationOverride: (block, trial) => block == 2 && trial == 3
          ? ContinuousAttentionConfig.stimulusDurationMs +
                ContinuousAttentionConfig.timingToleranceMs
          : null,
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.indicators.sessionValid, isTrue);
    expect(result.indicators.timingDeviationCount, 0);
  });

  test('dérive onset 100 ms acceptée, 101 ms invalide', () {
    ContinuousAttentionMetrics build(int drift) => _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isTest && target,
      actualOnsetOffsetOverride: (block, trial) =>
          block == 2 && trial == 3 ? drift : null,
    );

    expect(
      scoring
          .score(sessionId: sessionId, metrics: build(100))
          .indicators
          .sessionValid,
      isTrue,
    );
    final invalid = scoring.score(sessionId: sessionId, metrics: build(101));
    expect(invalid.indicators.sessionValid, isFalse);
    expect(invalid.indicators.timingDeviationCount, 1);
  });

  test('répondre jamais ou toujours produit 50/100', () {
    final never = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(sessionId, shouldRespond: (_, _, _) => false),
    );
    final always = scoring.score(
      sessionId: sessionId,
      metrics: _metrics(sessionId, shouldRespond: (_, _, _) => true),
    );

    expect(never.score.rawPoints, 50);
    expect(always.score.rawPoints, 50);
  });

  test('arrondi rationnel exact: 14.5 devient 15', () {
    var axNonTargetIndex = 0;
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) {
        if (phase == ContinuousAttentionPhase.xTest) return !target;
        if (phase == ContinuousAttentionPhase.axTest) {
          if (target) return false;
          return axNonTargetIndex++ < 210;
        }
        return false;
      },
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.indicators.xPhase.hitCount, 0);
    expect(result.indicators.xPhase.correctRejectionCount, 0);
    expect(result.indicators.axPhase.hitCount, 0);
    expect(result.indicators.axPhase.correctRejectionCount, 290);
    expect(result.indicators.axPhase.balancedAccuracyPercent, 29.0);
    expect(result.score.rawPoints, 15);
  });

  test('breakdown mock conserve 29.0 % au demi-point', () async {
    final repository = GamesMockRepository();
    final session = await repository.startSession(GameType.continuousAttention);
    var axNonTargetIndex = 0;
    final metrics = _metrics(
      session.id,
      shouldRespond: (phase, target, _) {
        if (phase == ContinuousAttentionPhase.xTest) return !target;
        if (phase == ContinuousAttentionPhase.axTest) {
          if (target) return false;
          return axNonTargetIndex++ < 210;
        }
        return false;
      },
    );

    final completed = await repository.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.continuousAttentionCore,
      metrics: metrics,
    );

    expect(completed.lastAttempt?.score.rawPoints, 15);
    expect(completed.scoreBreakdown[1].detail, '0.0 %');
    expect(completed.scoreBreakdown[2].detail, '29.0 %');
  });

  test('interruption/background invalide la session sans score clinique', () {
    final base = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isTest && target,
    );
    final metrics = ContinuousAttentionMetrics(
      blocks: base.blocks,
      sessionCompleted: true,
      interrupted: true,
      backgroundEventCount: 1,
      droppedFrameCount: 2,
    );

    final result = scoring.score(sessionId: sessionId, metrics: metrics);

    expect(result.score.rawPoints, 100);
    expect(result.score.level, 'Descriptive — provisional');
    expect(result.indicators.sessionValid, isFalse);
    expect(
      result.indicators.validityIssues,
      containsAll(['INTERRUPTED', 'BACKGROUND_EVENT']),
    );
  });

  test('latence 690 ms est rejetée', () {
    final metrics = _metrics(
      sessionId,
      shouldRespond: (phase, target, _) => phase.isTest && target,
      responseLatencyMs: 690,
    );

    expect(
      () => scoring.score(sessionId: sessionId, metrics: metrics),
      throwsArgumentError,
    );
  });

  test('mock repository renvoie le rapport et termine la session', () async {
    final repository = GamesMockRepository();
    final session = await repository.startSession(GameType.continuousAttention);
    final metrics = _metrics(
      session.id,
      shouldRespond: (phase, target, _) => phase.isTest && target,
    );

    final completed = await repository.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.continuousAttentionCore,
      metrics: metrics,
    );

    expect(completed.isCompleted, isTrue);
    expect(completed.lastAttempt?.score.rawPoints, 100);
    expect(
      completed.continuousAttentionIndicators?.provisionalAccuracyScore,
      100,
    );
    expect(
      completed.scoreBreakdown
          .map((line) => (line.label, line.detail, line.points, line.maxPoints))
          .toList(),
      [
        (
          'Score provisoire = moyenne de la balanced accuracy X_TEST et '
              'AX_TEST, arrondie une seule fois. Entraînement, temps, d-prime '
              'et biais c sont hors score.',
          null,
          null,
          null,
        ),
        ('X_TEST — balanced accuracy', '100.0 %', null, null),
        ('AX_TEST — balanced accuracy', '100.0 %', null, null),
        ('Validité technique', 'valide', null, null),
        ('Score descriptif', null, 100, 100),
      ],
    );
  });

  test('mock audite une session invalide sans muter la tentative', () async {
    final repository = GamesMockRepository();
    final session = await repository.startSession(GameType.continuousAttention);
    final invalid = _metrics(
      session.id,
      shouldRespond: (phase, target, _) => phase.isTest && target,
      displayDurationOverride: (block, trial) =>
          block == 0 && trial == 0 ? 1000 : null,
    );

    final audited = await repository.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.continuousAttentionCore,
      metrics: invalid,
    );
    expect(audited.status, 'IN_PROGRESS');
    expect(audited.attempts, isEmpty);
    expect(audited.continuousAttentionIndicators?.sessionValid, isFalse);
    expect(audited.scoreBreakdown, hasLength(5));
    expect(audited.scoreBreakdown[3].label, 'Validité technique');
    expect(audited.scoreBreakdown[3].detail, 'TIMING_DEVIATION');

    final valid = _metrics(
      session.id,
      shouldRespond: (phase, target, _) => phase.isTest && target,
    );
    final completed = await repository.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.continuousAttentionCore,
      metrics: valid,
    );
    expect(completed.attempts, hasLength(1));
    expect(completed.isCompleted, isTrue);
  });

  test(
    'mock refuse un type étranger et une seconde tentative validée',
    () async {
      final repository = GamesMockRepository();
      final moveFast = await repository.startSession(GameType.moveFast);
      final foreignMetrics = _metrics(
        moveFast.id,
        shouldRespond: (phase, target, _) => phase.isTest && target,
      );

      await expectLater(
        repository.submitResult(
          sessionId: moveFast.id,
          miniGame: MiniGame.continuousAttentionCore,
          metrics: foreignMetrics,
        ),
        throwsStateError,
      );

      final attention = await repository.startSession(
        GameType.continuousAttention,
      );
      final valid = _metrics(
        attention.id,
        shouldRespond: (phase, target, _) => phase.isTest && target,
      );
      await repository.submitResult(
        sessionId: attention.id,
        miniGame: MiniGame.continuousAttentionCore,
        metrics: valid,
      );

      await expectLater(
        repository.submitResult(
          sessionId: attention.id,
          miniGame: MiniGame.continuousAttentionCore,
          metrics: valid,
        ),
        throwsStateError,
      );
    },
  );
}

typedef _ResponseRule =
    bool Function(
      ContinuousAttentionPhase phase,
      bool isTarget,
      int trialIndex,
    );

ContinuousAttentionMetrics _metrics(
  String sessionId, {
  required _ResponseRule shouldRespond,
  int responseLatencyMs = 300,
  int? Function(int blockPosition, int trialPosition)? displayDurationOverride,
  int? Function(int blockPosition, int trialPosition)?
  actualOnsetOffsetOverride,
}) {
  final sequence = ContinuousAttentionConfig.generateSequence(sessionId);
  final phaseTrialPositions = <ContinuousAttentionPhase, int>{};
  final blocks = <ContinuousAttentionBlockMetric>[];

  for (
    var blockPosition = 0;
    blockPosition < sequence.length;
    blockPosition++
  ) {
    final block = sequence[blockPosition];
    final trials = <ContinuousAttentionTrialMetric>[];
    for (
      var trialPosition = 0;
      trialPosition < block.trials.length;
      trialPosition++
    ) {
      final stimulus = block.trials[trialPosition];
      final phasePosition = phaseTrialPositions.update(
        block.phase,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final onset =
          phasePosition *
          (ContinuousAttentionConfig.stimulusDurationMs +
              ContinuousAttentionConfig.interStimulusDurationMs);
      final responded = shouldRespond(
        block.phase,
        stimulus.isTarget,
        trialPosition,
      );
      final actualOnset =
          onset +
          (actualOnsetOffsetOverride?.call(blockPosition, trialPosition) ?? 0);
      trials.add(
        ContinuousAttentionTrialMetric(
          trialIndex: trialPosition + 1,
          previousLetter: stimulus.previousLetter,
          currentLetter: stimulus.currentLetter,
          responseCode: responded ? 57 : 0,
          correct: stimulus.isTarget == responded ? 1 : 0,
          latencyMs: responded ? responseLatencyMs : null,
          scheduledOnsetMs: onset,
          actualOnsetMs: actualOnset,
          responseTimestampMs: responded
              ? actualOnset + responseLatencyMs
              : null,
          actualDisplayDurationMs:
              displayDurationOverride?.call(blockPosition, trialPosition) ??
              ContinuousAttentionConfig.stimulusDurationMs,
          actualIsiDurationMs:
              ContinuousAttentionConfig.interStimulusDurationMs,
          inputSource: responded ? ContinuousAttentionInputSource.touch : null,
          extraResponseCount: 0,
          interrupted: false,
        ),
      );
    }
    blocks.add(
      ContinuousAttentionBlockMetric(
        phase: block.phase,
        blockIndex: block.blockIndex,
        trials: trials,
      ),
    );
  }

  return ContinuousAttentionMetrics(
    blocks: blocks,
    sessionCompleted: true,
    interrupted: false,
    backgroundEventCount: 0,
    droppedFrameCount: 0,
  );
}
