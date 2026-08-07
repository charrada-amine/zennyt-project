import '../config/continuous_attention_config.dart';
import 'game_metrics.dart';

enum ContinuousAttentionInputSource {
  touch('TOUCH'),
  keyboard('KEYBOARD');

  const ContinuousAttentionInputSource(this.wire);

  final String wire;
}

/// Mesure brute d'un stimulus. Le client ne soumet aucun score.
class ContinuousAttentionTrialMetric {
  const ContinuousAttentionTrialMetric({
    required this.trialIndex,
    required this.previousLetter,
    required this.currentLetter,
    required this.responseCode,
    required this.correct,
    required this.latencyMs,
    required this.scheduledOnsetMs,
    required this.actualOnsetMs,
    required this.responseTimestampMs,
    required this.actualDisplayDurationMs,
    required this.actualIsiDurationMs,
    required this.inputSource,
    required this.extraResponseCount,
    required this.interrupted,
  });

  final int trialIndex;
  final String? previousLetter;
  final String currentLetter;
  final int responseCode;
  final int correct;
  final int? latencyMs;
  final int scheduledOnsetMs;
  final int actualOnsetMs;
  final int? responseTimestampMs;
  final int actualDisplayDurationMs;
  final int actualIsiDurationMs;
  final ContinuousAttentionInputSource? inputSource;
  final int extraResponseCount;
  final bool interrupted;

  bool get responded => responseCode == 57;

  Map<String, dynamic> toJson() => {
    'trialIndex': trialIndex,
    'previousLetter': previousLetter,
    'currentLetter': currentLetter,
    'responseCode': responseCode,
    'correct': correct,
    'latencyMs': latencyMs,
    'scheduledOnsetMs': scheduledOnsetMs,
    'actualOnsetMs': actualOnsetMs,
    'responseTimestampMs': responseTimestampMs,
    'actualDisplayDurationMs': actualDisplayDurationMs,
    'actualIsiDurationMs': actualIsiDurationMs,
    'inputSource': inputSource?.wire,
    'extraResponseCount': extraResponseCount,
    'interrupted': interrupted,
  };
}

class ContinuousAttentionBlockMetric {
  ContinuousAttentionBlockMetric({
    required this.phase,
    required this.blockIndex,
    required List<ContinuousAttentionTrialMetric> trials,
  }) : trials = List.unmodifiable(trials);

  final ContinuousAttentionPhase phase;
  final int blockIndex;
  final List<ContinuousAttentionTrialMetric> trials;

  Map<String, dynamic> toJson() => {
    'phase': phase.wire,
    'blockIndex': blockIndex,
    'trials': trials.map((trial) => trial.toJson()).toList(),
  };
}

/// Les 44 blocs bruts du protocole Long Rosvold X/AX.
class ContinuousAttentionMetrics extends GameMetrics {
  ContinuousAttentionMetrics({
    required List<ContinuousAttentionBlockMetric> blocks,
    required this.sessionCompleted,
    required this.interrupted,
    required this.backgroundEventCount,
    required this.droppedFrameCount,
    this.protocolVersion = ContinuousAttentionConfig.protocolVersion,
  }) : blocks = List.unmodifiable(blocks);

  final String protocolVersion;
  final List<ContinuousAttentionBlockMetric> blocks;
  final bool sessionCompleted;
  final bool interrupted;
  final int backgroundEventCount;
  final int droppedFrameCount;

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'blocks': blocks.map((block) => block.toJson()).toList(),
    'sessionCompleted': sessionCompleted,
    'interrupted': interrupted,
    'backgroundEventCount': backgroundEventCount,
    'droppedFrameCount': droppedFrameCount,
  };
}

class ContinuousAttentionEpochIndicators {
  const ContinuousAttentionEpochIndicators({
    required this.phase,
    required this.epochIndex,
    required this.hitRatePercent,
    required this.falseAlarmRatePercent,
    required this.averageHitReactionTimeMs,
    required this.reactionTimeVariabilityMs,
    required this.dPrime,
  });

  final ContinuousAttentionPhase phase;
  final int epochIndex;
  final double hitRatePercent;
  final double falseAlarmRatePercent;
  final double? averageHitReactionTimeMs;
  final double? reactionTimeVariabilityMs;
  final double dPrime;

  factory ContinuousAttentionEpochIndicators.fromJson(
    Map<String, dynamic> json,
  ) => ContinuousAttentionEpochIndicators(
    phase: ContinuousAttentionPhase.fromWire(json['phase'] as String),
    epochIndex: (json['epochIndex'] as num?)?.toInt() ?? 0,
    hitRatePercent: (json['hitRatePercent'] as num?)?.toDouble() ?? 0,
    falseAlarmRatePercent:
        (json['falseAlarmRatePercent'] as num?)?.toDouble() ?? 0,
    averageHitReactionTimeMs: (json['averageHitReactionTimeMs'] as num?)
        ?.toDouble(),
    reactionTimeVariabilityMs: (json['reactionTimeVariabilityMs'] as num?)
        ?.toDouble(),
    dPrime: (json['dPrime'] as num?)?.toDouble() ?? 0,
  );
}

class ContinuousAttentionPhaseIndicators {
  const ContinuousAttentionPhaseIndicators({
    required this.phase,
    required this.targetCount,
    required this.nonTargetCount,
    required this.hitCount,
    required this.omissionCount,
    required this.commissionCount,
    required this.correctRejectionCount,
    required this.hitRatePercent,
    required this.omissionRatePercent,
    required this.falseAlarmRatePercent,
    required this.correctRejectionRatePercent,
    required this.balancedAccuracyPercent,
    required this.averageHitReactionTimeMs,
    required this.medianHitReactionTimeMs,
    required this.stdDevHitReactionTimeMs,
    required this.reactionTimeCoefficientOfVariation,
    required this.dPrime,
    required this.responseBiasC,
  });

  final ContinuousAttentionPhase phase;
  final int targetCount;
  final int nonTargetCount;
  final int hitCount;
  final int omissionCount;
  final int commissionCount;
  final int correctRejectionCount;
  final double hitRatePercent;
  final double omissionRatePercent;
  final double falseAlarmRatePercent;
  final double correctRejectionRatePercent;
  final double balancedAccuracyPercent;
  final double? averageHitReactionTimeMs;
  final double? medianHitReactionTimeMs;
  final double? stdDevHitReactionTimeMs;
  final double? reactionTimeCoefficientOfVariation;
  final double dPrime;
  final double responseBiasC;

  factory ContinuousAttentionPhaseIndicators.fromJson(
    Map<String, dynamic> json,
  ) => ContinuousAttentionPhaseIndicators(
    phase: ContinuousAttentionPhase.fromWire(json['phase'] as String),
    targetCount: (json['targetCount'] as num?)?.toInt() ?? 0,
    nonTargetCount: (json['nonTargetCount'] as num?)?.toInt() ?? 0,
    hitCount: (json['hitCount'] as num?)?.toInt() ?? 0,
    omissionCount: (json['omissionCount'] as num?)?.toInt() ?? 0,
    commissionCount: (json['commissionCount'] as num?)?.toInt() ?? 0,
    correctRejectionCount:
        (json['correctRejectionCount'] as num?)?.toInt() ?? 0,
    hitRatePercent: (json['hitRatePercent'] as num?)?.toDouble() ?? 0,
    omissionRatePercent: (json['omissionRatePercent'] as num?)?.toDouble() ?? 0,
    falseAlarmRatePercent:
        (json['falseAlarmRatePercent'] as num?)?.toDouble() ?? 0,
    correctRejectionRatePercent:
        (json['correctRejectionRatePercent'] as num?)?.toDouble() ?? 0,
    balancedAccuracyPercent:
        (json['balancedAccuracyPercent'] as num?)?.toDouble() ?? 0,
    averageHitReactionTimeMs: (json['averageHitReactionTimeMs'] as num?)
        ?.toDouble(),
    medianHitReactionTimeMs: (json['medianHitReactionTimeMs'] as num?)
        ?.toDouble(),
    stdDevHitReactionTimeMs: (json['stdDevHitReactionTimeMs'] as num?)
        ?.toDouble(),
    reactionTimeCoefficientOfVariation:
        (json['reactionTimeCoefficientOfVariation'] as num?)?.toDouble(),
    dPrime: (json['dPrime'] as num?)?.toDouble() ?? 0,
    responseBiasC: (json['responseBiasC'] as num?)?.toDouble() ?? 0,
  );
}

/// Indicateurs descriptifs calculés par le serveur ou le mock de parité.
class ContinuousAttentionIndicators {
  ContinuousAttentionIndicators({
    required this.protocolVersion,
    required this.completed,
    required this.sessionValid,
    required this.interrupted,
    required this.provisionalAccuracyScore,
    required this.xPhase,
    required this.axPhase,
    required List<ContinuousAttentionEpochIndicators> epochs,
    required this.axTargetCount,
    required this.ayCount,
    required this.bxCount,
    required this.byCount,
    required this.extraResponseCount,
    required this.backgroundEventCount,
    required this.droppedFrameCount,
    required this.timingDeviationCount,
    required List<String> validityIssues,
  }) : epochs = List.unmodifiable(epochs),
       validityIssues = List.unmodifiable(validityIssues);

  final String protocolVersion;
  final bool completed;
  final bool sessionValid;
  final bool interrupted;
  final int provisionalAccuracyScore;
  final ContinuousAttentionPhaseIndicators xPhase;
  final ContinuousAttentionPhaseIndicators axPhase;
  final List<ContinuousAttentionEpochIndicators> epochs;
  final int axTargetCount;
  final int ayCount;
  final int bxCount;
  final int byCount;
  final int extraResponseCount;
  final int backgroundEventCount;
  final int droppedFrameCount;
  final int timingDeviationCount;
  final List<String> validityIssues;

  factory ContinuousAttentionIndicators.fromJson(Map<String, dynamic> json) {
    return ContinuousAttentionIndicators(
      protocolVersion: json['protocolVersion'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      sessionValid: json['sessionValid'] as bool? ?? false,
      interrupted: json['interrupted'] as bool? ?? false,
      provisionalAccuracyScore:
          (json['provisionalAccuracyScore'] as num?)?.toInt() ?? 0,
      xPhase: ContinuousAttentionPhaseIndicators.fromJson(
        json['xPhase'] as Map<String, dynamic>? ?? const {},
      ),
      axPhase: ContinuousAttentionPhaseIndicators.fromJson(
        json['axPhase'] as Map<String, dynamic>? ?? const {},
      ),
      epochs:
          (json['epochs'] as List<dynamic>?)
              ?.map(
                (value) => ContinuousAttentionEpochIndicators.fromJson(
                  value as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      axTargetCount: (json['axTargetCount'] as num?)?.toInt() ?? 0,
      ayCount: (json['ayCount'] as num?)?.toInt() ?? 0,
      bxCount: (json['bxCount'] as num?)?.toInt() ?? 0,
      byCount: (json['byCount'] as num?)?.toInt() ?? 0,
      extraResponseCount: (json['extraResponseCount'] as num?)?.toInt() ?? 0,
      backgroundEventCount:
          (json['backgroundEventCount'] as num?)?.toInt() ?? 0,
      droppedFrameCount: (json['droppedFrameCount'] as num?)?.toInt() ?? 0,
      timingDeviationCount:
          (json['timingDeviationCount'] as num?)?.toInt() ?? 0,
      validityIssues:
          (json['validityIssues'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const [],
    );
  }
}
