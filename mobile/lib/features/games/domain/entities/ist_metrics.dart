import '../config/ist_config.dart';
import 'game_metrics.dart';

/// Une case ouverte ; sa couleur n'est jamais transmise.
class IstBoxOpening {
  const IstBoxOpening({required this.boxIndex, required this.timestampMs});
  final int boxIndex;
  final int timestampMs;

  Map<String, dynamic> toJson() => {
    'boxIndex': boxIndex,
    'timestampMs': timestampMs,
  };
}

class IstTrialMetric {
  IstTrialMetric({
    required this.trialIndex,
    required List<IstBoxOpening> openings,
    required this.chosenColor,
    required this.decisionTimestampMs,
    this.confidence,
  }) : openings = List.unmodifiable(openings);

  final int trialIndex;
  final List<IstBoxOpening> openings;
  final IstColor chosenColor;
  final int decisionTimestampMs;

  /// 1..4, ou null si le joueur a passé.
  final int? confidence;

  IstTrialSlot get slot => IstConfig.trialOrder[trialIndex];

  Map<String, dynamic> toJson() => {
    'trialIndex': trialIndex,
    'phase': slot.phase.wire,
    'condition': slot.condition.wire,
    'openings': openings.map((o) => o.toJson()).toList(),
    'chosenColor': chosenColor.wire,
    'decisionTimestampMs': decisionTimestampMs,
    'confidence': confidence,
  };
}

class IstMetrics extends GameMetrics {
  IstMetrics({
    required List<IstTrialMetric> trials,
    required this.interrupted,
    required this.backgroundEventCount,
    required this.focusLossCount,
  }) : trials = List.unmodifiable(trials);

  final List<IstTrialMetric> trials;
  final bool interrupted;
  final int backgroundEventCount;
  final int focusLossCount;

  bool get sessionCompleted => trials.length == IstConfig.totalTrialCount;

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': IstConfig.protocolVersion,
    'istTrials': trials.map((t) => t.toJson()).toList(),
    'sessionCompleted': sessionCompleted,
    'interrupted': interrupted,
    'backgroundEventCount': backgroundEventCount,
    'focusLossCount': focusLossCount,
  };
}

/// Indicateurs IST. [calibrationBias] est descriptif et hors score ; aucune
/// sensibilité métacognitive n'est calculée (20 essais n'y suffisent pas).
class IstIndicators {
  const IstIndicators({
    required this.sessionValid,
    required this.validityIssues,
    required this.testTrialCount,
    required this.correctCount,
    required this.accuracyPercent,
    required this.meanBoxesFixedWin,
    required this.meanBoxesDecreasingWin,
    required this.conditionDiscrimination,
    required this.meanPCorrectAtDecision,
    required this.meanPCorrectFixedWin,
    required this.meanPCorrectDecreasingWin,
    required this.totalEarnings,
    required this.randomResponseCount,
    required this.medianInterActionIntervalMs,
    required this.confidenceResponseCount,
    required this.calibrationBias,
    required this.provisionalScore,
  });

  final bool sessionValid;
  final List<String> validityIssues;
  final int testTrialCount;
  final int correctCount;
  final double accuracyPercent;
  final double meanBoxesFixedWin;
  final double meanBoxesDecreasingWin;
  final double conditionDiscrimination;
  final double meanPCorrectAtDecision;
  final double meanPCorrectFixedWin;
  final double meanPCorrectDecreasingWin;
  final int totalEarnings;
  final int randomResponseCount;
  final double? medianInterActionIntervalMs;
  final int confidenceResponseCount;
  final double? calibrationBias;
  final int provisionalScore;

  factory IstIndicators.fromJson(Map<String, dynamic> json) => IstIndicators(
    sessionValid: json['sessionValid'] as bool,
    validityIssues: List<String>.from(
      json['validityIssues'] as List? ?? const [],
    ),
    testTrialCount: json['testTrialCount'] as int,
    correctCount: json['correctCount'] as int,
    accuracyPercent: (json['accuracyPercent'] as num).toDouble(),
    meanBoxesFixedWin: (json['meanBoxesFixedWin'] as num).toDouble(),
    meanBoxesDecreasingWin: (json['meanBoxesDecreasingWin'] as num).toDouble(),
    conditionDiscrimination: (json['conditionDiscrimination'] as num)
        .toDouble(),
    meanPCorrectAtDecision: (json['meanPCorrectAtDecision'] as num).toDouble(),
    meanPCorrectFixedWin: (json['meanPCorrectFixedWin'] as num).toDouble(),
    meanPCorrectDecreasingWin: (json['meanPCorrectDecreasingWin'] as num)
        .toDouble(),
    totalEarnings: json['totalEarnings'] as int,
    randomResponseCount: json['randomResponseCount'] as int,
    medianInterActionIntervalMs: (json['medianInterActionIntervalMs'] as num?)
        ?.toDouble(),
    confidenceResponseCount: json['confidenceResponseCount'] as int,
    calibrationBias: (json['calibrationBias'] as num?)?.toDouble(),
    provisionalScore: json['provisionalScore'] as int,
  );
}
