import '../config/bart_config.dart';
import 'game_metrics.dart';

/// Un ballon tel que mesuré. Le client ne déclare jamais le point d'éclatement
/// ni les points : le serveur rejoue les pompes contre sa propre séquence.
class BartBalloonMetric {
  BartBalloonMetric({
    required this.balloonIndex,
    required this.pumpCount,
    required this.outcome,
    required List<int> pumpTimestampsMs,
    this.collectTimestampMs,
  }) : phase = BartConfig.phaseOf(balloonIndex),
       pumpTimestampsMs = List.unmodifiable(pumpTimestampsMs);

  final int balloonIndex;
  final BartPhase phase;
  final int pumpCount;
  final BartBalloonOutcome outcome;
  final List<int> pumpTimestampsMs;
  final int? collectTimestampMs;

  Map<String, dynamic> toJson() => {
    'balloonIndex': balloonIndex,
    'phase': phase.wire,
    'pumpCount': pumpCount,
    'outcome': outcome.wire,
    'pumpTimestampsMs': pumpTimestampsMs,
    'collectTimestampMs': collectTimestampMs,
  };
}

/// Trace brute complète du BART.
class BartMetrics extends GameMetrics {
  BartMetrics({
    required List<BartBalloonMetric> balloons,
    required this.interrupted,
    required this.backgroundEventCount,
    required this.focusLossCount,
  }) : balloons = List.unmodifiable(balloons);

  final List<BartBalloonMetric> balloons;
  final bool interrupted;
  final int backgroundEventCount;
  final int focusLossCount;

  bool get sessionCompleted => balloons.length == BartConfig.totalBalloonCount;

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': BartConfig.protocolVersion,
    'bartBalloons': balloons.map((b) => b.toJson()).toList(),
    'sessionCompleted': sessionCompleted,
    'interrupted': interrupted,
    'backgroundEventCount': backgroundEventCount,
    'focusLossCount': focusLossCount,
  };
}

/// Indicateurs BART calculés serveur (ou par le mock, à l'identique).
/// [efficiencyPercent] est le seul axe noté ; [adjustedAveragePumps] est un
/// TRAIT descriptif — ni haut ni bas n'est meilleur.
class BartIndicators {
  const BartIndicators({
    required this.sessionValid,
    required this.validityIssues,
    required this.testBalloonCount,
    required this.collectedCount,
    required this.explosionCount,
    required this.adjustedAveragePumps,
    required this.totalEarnings,
    required this.evOptimalEarnings,
    required this.optimalFixedPumps,
    required this.efficiencyPercent,
    required this.meanPumpsAfterExplosion,
    required this.meanPumpsAfterCollect,
    required this.medianInterPumpIntervalMs,
  });

  final bool sessionValid;
  final List<String> validityIssues;
  final int testBalloonCount;
  final int collectedCount;
  final int explosionCount;
  final double? adjustedAveragePumps;
  final int totalEarnings;
  final int evOptimalEarnings;
  final int optimalFixedPumps;
  final int efficiencyPercent;
  final double? meanPumpsAfterExplosion;
  final double? meanPumpsAfterCollect;
  final double? medianInterPumpIntervalMs;

  factory BartIndicators.fromJson(Map<String, dynamic> json) => BartIndicators(
    sessionValid: json['sessionValid'] as bool,
    validityIssues: List<String>.from(json['validityIssues'] as List? ?? const []),
    testBalloonCount: json['testBalloonCount'] as int,
    collectedCount: json['collectedCount'] as int,
    explosionCount: json['explosionCount'] as int,
    adjustedAveragePumps: (json['adjustedAveragePumps'] as num?)?.toDouble(),
    totalEarnings: json['totalEarnings'] as int,
    evOptimalEarnings: json['evOptimalEarnings'] as int,
    optimalFixedPumps: json['optimalFixedPumps'] as int,
    efficiencyPercent: json['efficiencyPercent'] as int,
    meanPumpsAfterExplosion: (json['meanPumpsAfterExplosion'] as num?)?.toDouble(),
    meanPumpsAfterCollect: (json['meanPumpsAfterCollect'] as num?)?.toDouble(),
    medianInterPumpIntervalMs: (json['medianInterPumpIntervalMs'] as num?)?.toDouble(),
  );
}
