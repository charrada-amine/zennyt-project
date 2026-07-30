import 'dart:math' as math;

import '../domain/config/continuous_attention_config.dart';
import '../domain/config/continuous_attention_provisional_rules.dart';
import '../domain/entities/continuous_attention_metrics.dart';
import '../domain/entities/game_score.dart';

/// Résultat du miroir mobile du calcul serveur « Je continue ».
class ContinuousAttentionScoreResult {
  const ContinuousAttentionScoreResult({
    required this.score,
    required this.indicators,
  });

  final GameScore score;
  final ContinuousAttentionIndicators indicators;
}

/// Miroir hors-ligne du score provisoire et des indicateurs descriptifs.
///
/// Source serveur correspondante :
/// `backend/.../ContinuousAttentionScoringService.java`.
/// Le score n'utilise que la balanced accuracy des phases X_TEST et AX_TEST.
/// Les temps, d-prime et biais de réponse restent descriptifs.
class ContinuousAttentionScoring {
  const ContinuousAttentionScoring();

  ContinuousAttentionScoreResult score({
    required String sessionId,
    required ContinuousAttentionMetrics metrics,
  }) {
    _validateStructure(sessionId, metrics);

    final xTrials = _testTrials(metrics, ContinuousAttentionPhase.xTest);
    final axTrials = _testTrials(metrics, ContinuousAttentionPhase.axTest);
    final x = _phaseIndicators(ContinuousAttentionPhase.xTest, xTrials);
    final ax = _phaseIndicators(ContinuousAttentionPhase.axTest, axTrials);
    final provisionalScore =
        ContinuousAttentionProvisionalRules.scoreFromPhaseCounts(
          xHits: x.hitCount,
          xTargets: x.targetCount,
          xCorrectRejections: x.correctRejectionCount,
          xNonTargets: x.nonTargetCount,
          axHits: ax.hitCount,
          axTargets: ax.targetCount,
          axCorrectRejections: ax.correctRejectionCount,
          axNonTargets: ax.nonTargetCount,
        );

    final allTrials = metrics.blocks.expand((block) => block.trials).toList();
    final hasInterruptedTrial = allTrials.any((trial) => trial.interrupted);
    final interrupted = metrics.interrupted || hasInterruptedTrial;
    final timingDeviationCount = allTrials
        .where(
          (trial) =>
              (trial.actualOnsetMs - trial.scheduledOnsetMs).abs() >
                  ContinuousAttentionConfig.timingToleranceMs ||
              (trial.actualDisplayDurationMs -
                          ContinuousAttentionConfig.stimulusDurationMs)
                      .abs() >
                  ContinuousAttentionConfig.timingToleranceMs ||
              (trial.actualIsiDurationMs -
                          ContinuousAttentionConfig.interStimulusDurationMs)
                      .abs() >
                  ContinuousAttentionConfig.timingToleranceMs,
        )
        .length;
    final validityIssues = <String>[
      if (!metrics.sessionCompleted) 'SESSION_INCOMPLETE',
      if (interrupted) 'INTERRUPTED',
      if (metrics.backgroundEventCount > 0) 'BACKGROUND_EVENT',
      if (timingDeviationCount > 0) 'TIMING_DEVIATION',
    ];
    final completed = metrics.sessionCompleted;
    final sessionValid = completed && validityIssues.isEmpty;
    final axPairCounts = _axPairCounts(axTrials);

    final indicators = ContinuousAttentionIndicators(
      protocolVersion: metrics.protocolVersion,
      completed: completed,
      sessionValid: sessionValid,
      interrupted: interrupted,
      provisionalAccuracyScore: provisionalScore,
      xPhase: x,
      axPhase: ax,
      epochs: [
        ..._epochs(metrics, ContinuousAttentionPhase.xTest),
        ..._epochs(metrics, ContinuousAttentionPhase.axTest),
      ],
      axTargetCount: axPairCounts.ax,
      ayCount: axPairCounts.ay,
      bxCount: axPairCounts.bx,
      byCount: axPairCounts.by,
      extraResponseCount: allTrials.fold(
        0,
        (sum, trial) => sum + trial.extraResponseCount,
      ),
      backgroundEventCount: metrics.backgroundEventCount,
      droppedFrameCount: metrics.droppedFrameCount,
      timingDeviationCount: timingDeviationCount,
      validityIssues: validityIssues,
    );

    return ContinuousAttentionScoreResult(
      score: GameScore(
        rawPoints: provisionalScore,
        maxPoints: 100,
        normalized: provisionalScore.toDouble(),
        level: ContinuousAttentionProvisionalRules.neutralLevel,
      ),
      indicators: indicators,
    );
  }

  void _validateStructure(
    String sessionId,
    ContinuousAttentionMetrics metrics,
  ) {
    if (metrics.protocolVersion != ContinuousAttentionConfig.protocolVersion) {
      throw ArgumentError('Unsupported continuous-attention protocol');
    }
    if (metrics.blocks.length != ContinuousAttentionConfig.totalBlocks) {
      throw ArgumentError(
        'Je continue requires exactly '
        '${ContinuousAttentionConfig.totalBlocks} blocks',
      );
    }

    final expected = ContinuousAttentionConfig.generateSequence(sessionId);
    final phaseTrialPositions = <ContinuousAttentionPhase, int>{};
    final lastActualOnsets = <ContinuousAttentionPhase, int>{};
    for (
      var blockPosition = 0;
      blockPosition < expected.length;
      blockPosition++
    ) {
      final expectedBlock = expected[blockPosition];
      final actualBlock = metrics.blocks[blockPosition];
      if (actualBlock.phase != expectedBlock.phase ||
          actualBlock.blockIndex != expectedBlock.blockIndex ||
          actualBlock.trials.length !=
              ContinuousAttentionConfig.trialsPerBlock) {
        throw ArgumentError(
          'Invalid continuous-attention block at position $blockPosition',
        );
      }

      for (
        var trialPosition = 0;
        trialPosition < expectedBlock.trials.length;
        trialPosition++
      ) {
        final expectedTrial = expectedBlock.trials[trialPosition];
        final actualTrial = actualBlock.trials[trialPosition];
        final phaseTrialPosition = phaseTrialPositions.update(
          actualBlock.phase,
          (value) => value + 1,
          ifAbsent: () => 0,
        );
        final expectedScheduledOnset =
            phaseTrialPosition *
            (ContinuousAttentionConfig.stimulusDurationMs +
                ContinuousAttentionConfig.interStimulusDurationMs);
        if (actualTrial.trialIndex != trialPosition + 1 ||
            actualTrial.previousLetter != expectedTrial.previousLetter ||
            actualTrial.currentLetter != expectedTrial.currentLetter) {
          throw ArgumentError(
            'Invalid continuous-attention sequence at '
            'block $blockPosition trial $trialPosition',
          );
        }
        if (actualTrial.scheduledOnsetMs != expectedScheduledOnset) {
          throw ArgumentError('Invalid absolute scheduled onset');
        }
        final lastActualOnset = lastActualOnsets[actualBlock.phase];
        if (actualTrial.actualOnsetMs < 0 ||
            (lastActualOnset != null &&
                actualTrial.actualOnsetMs <= lastActualOnset)) {
          throw ArgumentError('Actual onsets must be strictly monotonic');
        }
        lastActualOnsets[actualBlock.phase] = actualTrial.actualOnsetMs;
        if (actualTrial.actualDisplayDurationMs < 0 ||
            actualTrial.actualIsiDurationMs < 0 ||
            actualTrial.extraResponseCount < 0) {
          throw ArgumentError('Durations and counters must be non-negative');
        }

        final responded = actualTrial.responseCode == 57;
        if (actualTrial.responseCode != 0 && !responded) {
          throw ArgumentError('responseCode must be 0 or 57');
        }
        if (responded) {
          final latency = actualTrial.latencyMs;
          if (latency == null ||
              !ContinuousAttentionConfig.acceptsResponseLatencyMs(latency) ||
              actualTrial.responseTimestampMs == null ||
              actualTrial.inputSource == null) {
            throw ArgumentError('Invalid response timing/source');
          }
          if (actualTrial.responseTimestampMs! - actualTrial.actualOnsetMs !=
              latency) {
            throw ArgumentError(
              'responseTimestampMs - actualOnsetMs must equal latencyMs',
            );
          }
        } else if (actualTrial.latencyMs != null ||
            actualTrial.responseTimestampMs != null ||
            actualTrial.inputSource != null) {
          throw ArgumentError('No-response trial must not contain a response');
        }

        final expectedCorrect = expectedTrial.isTarget == responded ? 1 : 0;
        if (actualTrial.correct != expectedCorrect) {
          throw ArgumentError('Client correct flag diverges from raw response');
        }
      }
    }
  }

  List<_ScoredTrial> _testTrials(
    ContinuousAttentionMetrics metrics,
    ContinuousAttentionPhase phase,
  ) {
    return [
      for (final block in metrics.blocks)
        if (block.phase == phase)
          for (final trial in block.trials)
            _ScoredTrial(
              blockIndex: block.blockIndex,
              metric: trial,
              isTarget: phase.isAx
                  ? trial.previousLetter == 'A' && trial.currentLetter == 'X'
                  : trial.currentLetter == 'X',
            ),
    ];
  }

  ContinuousAttentionPhaseIndicators _phaseIndicators(
    ContinuousAttentionPhase phase,
    List<_ScoredTrial> trials,
  ) {
    final targets = trials.where((trial) => trial.isTarget).toList();
    final nonTargets = trials.where((trial) => !trial.isTarget).toList();
    final hits = targets.where((trial) => trial.responded).toList();
    final omissions = targets.length - hits.length;
    final commissions = nonTargets.where((trial) => trial.responded).length;
    final correctRejections = nonTargets.length - commissions;
    final hitRatePercent = _percent(hits.length, targets.length);
    final omissionRatePercent = _percent(omissions, targets.length);
    final falseAlarmRatePercent = _percent(commissions, nonTargets.length);
    final correctRejectionRatePercent = _percent(
      correctRejections,
      nonTargets.length,
    );
    final hitLatencies = hits.map((trial) => trial.metric.latencyMs!).toList()
      ..sort();
    final average = _average(hitLatencies);
    final median = _median(hitLatencies);
    final stdDev = _populationStdDev(hitLatencies, average);
    final adjustedHitRate = (hits.length + .5) / (targets.length + 1);
    final adjustedFalseAlarmRate = (commissions + .5) / (nonTargets.length + 1);
    final zHit = _inverseNormalCdf(adjustedHitRate);
    final zFalseAlarm = _inverseNormalCdf(adjustedFalseAlarmRate);

    return ContinuousAttentionPhaseIndicators(
      phase: phase,
      targetCount: targets.length,
      nonTargetCount: nonTargets.length,
      hitCount: hits.length,
      omissionCount: omissions,
      commissionCount: commissions,
      correctRejectionCount: correctRejections,
      hitRatePercent: hitRatePercent,
      omissionRatePercent: omissionRatePercent,
      falseAlarmRatePercent: falseAlarmRatePercent,
      correctRejectionRatePercent: correctRejectionRatePercent,
      balancedAccuracyPercent:
          (hitRatePercent + correctRejectionRatePercent) / 2,
      averageHitReactionTimeMs: average,
      medianHitReactionTimeMs: median,
      stdDevHitReactionTimeMs: stdDev,
      reactionTimeCoefficientOfVariation:
          average == null || average == 0 || stdDev == null
          ? null
          : stdDev / average,
      dPrime: zHit - zFalseAlarm,
      responseBiasC: -.5 * (zHit + zFalseAlarm),
    );
  }

  List<ContinuousAttentionEpochIndicators> _epochs(
    ContinuousAttentionMetrics metrics,
    ContinuousAttentionPhase phase,
  ) {
    final allTrials = _testTrials(metrics, phase);
    return [
      for (var epoch = 1; epoch <= 4; epoch++)
        _epochIndicators(
          phase,
          epoch,
          allTrials
              .where(
                (trial) =>
                    trial.blockIndex >= ((epoch - 1) * 5) + 1 &&
                    trial.blockIndex <= epoch * 5,
              )
              .toList(),
        ),
    ];
  }

  ContinuousAttentionEpochIndicators _epochIndicators(
    ContinuousAttentionPhase phase,
    int epochIndex,
    List<_ScoredTrial> trials,
  ) {
    final phaseIndicators = _phaseIndicators(phase, trials);
    return ContinuousAttentionEpochIndicators(
      phase: phase,
      epochIndex: epochIndex,
      hitRatePercent: phaseIndicators.hitRatePercent,
      falseAlarmRatePercent: phaseIndicators.falseAlarmRatePercent,
      averageHitReactionTimeMs: phaseIndicators.averageHitReactionTimeMs,
      reactionTimeVariabilityMs: phaseIndicators.stdDevHitReactionTimeMs,
      dPrime: phaseIndicators.dPrime,
    );
  }

  ({int ax, int ay, int bx, int by}) _axPairCounts(List<_ScoredTrial> trials) {
    var ax = 0;
    var ay = 0;
    var bx = 0;
    var by = 0;
    for (final trial in trials) {
      final metric = trial.metric;
      if (metric.previousLetter == 'A' && metric.currentLetter == 'X') {
        ax++;
      } else if (metric.previousLetter == 'A') {
        ay++;
      } else if (metric.currentLetter == 'X') {
        bx++;
      } else {
        by++;
      }
    }
    return (ax: ax, ay: ay, bx: bx, by: by);
  }

  double _percent(int numerator, int denominator) =>
      denominator == 0 ? 0 : numerator * 100.0 / denominator;

  double? _average(List<int> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _median(List<int> sortedValues) {
    if (sortedValues.isEmpty) return null;
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) return sortedValues[middle].toDouble();
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  double? _populationStdDev(List<int> values, double? average) {
    if (values.isEmpty || average == null) return null;
    final variance =
        values
            .map((value) => math.pow(value - average, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  /// Acklam's rational approximation of the standard-normal inverse CDF.
  double _inverseNormalCdf(double probability) {
    const a1 = -39.6968302866538;
    const a2 = 220.946098424521;
    const a3 = -275.928510446969;
    const a4 = 138.357751867269;
    const a5 = -30.6647980661472;
    const a6 = 2.50662827745924;
    const b1 = -54.4760987982241;
    const b2 = 161.585836858041;
    const b3 = -155.698979859887;
    const b4 = 66.8013118877197;
    const b5 = -13.2806815528857;
    const c1 = -0.00778489400243029;
    const c2 = -0.322396458041136;
    const c3 = -2.40075827716184;
    const c4 = -2.54973253934373;
    const c5 = 4.37466414146497;
    const c6 = 2.93816398269878;
    const d1 = 0.00778469570904146;
    const d2 = 0.32246712907004;
    const d3 = 2.445134137143;
    const d4 = 3.75440866190742;
    const lower = 0.02425;
    const upper = 1 - lower;

    if (probability < lower) {
      final q = math.sqrt(-2 * math.log(probability));
      return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
          ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    }
    if (probability > upper) {
      final q = math.sqrt(-2 * math.log(1 - probability));
      return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
          ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    }
    final q = probability - .5;
    final r = q * q;
    return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) *
        q /
        (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
  }
}

class _ScoredTrial {
  const _ScoredTrial({
    required this.blockIndex,
    required this.metric,
    required this.isTarget,
  });

  final int blockIndex;
  final ContinuousAttentionTrialMetric metric;
  final bool isTarget;

  bool get responded => metric.responseCode == 57;
}
