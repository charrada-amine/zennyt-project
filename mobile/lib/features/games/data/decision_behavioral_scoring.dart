// PARITÉ MOCK ⇄ BACKEND — miroir exact de :
//   BartScoringService.java, BartActionReplayer.java,
//   IstScoringService.java, IstActionReplayer.java, IstPosteriorModel.java,
//   MetacognitionService.java, DecisionBehavioralStatistics.java,
//   ScoreBreakdownService.bart / .ist.
// Toute modification d'un côté impose la même modification de l'autre, dans la
// même PR. Les tests de parité (decision_behavioral_scoring_test.dart) figent les
// valeurs calculées par le Java pour une session de référence.

import '../domain/config/bart_config.dart';
import '../domain/config/bart_provisional_rules.dart';
import '../domain/config/ist_config.dart';
import '../domain/config/ist_provisional_rules.dart';
import '../domain/entities/bart_metrics.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/ist_metrics.dart';
import '../domain/entities/score_breakdown.dart';

/// Arrondi à 4 décimales, identique au Java : `floor(x × 10⁴ + 0,5) / 10⁴`.
double round4(double value) => (value * 10000.0 + 0.5).floor() / 10000.0;

double? _meanOrNull(List<num> values) {
  if (values.isEmpty) return null;
  var sum = 0.0;
  for (final value in values) {
    sum += value.toDouble();
  }
  return round4(sum / values.length);
}

double _meanOrZero(List<num> values) => _meanOrNull(values) ?? 0.0;

double? _medianOrNull(List<num> values) {
  if (values.isEmpty) return null;
  final sorted = values.map((v) => v.toDouble()).toList()..sort();
  final middle = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2.0;
  return round4(median);
}

GameScore _score(int points, int max, String level) => GameScore(
  rawPoints: points,
  maxPoints: max,
  normalized: max == 0 ? 0 : points * 100.0 / max,
  level: level,
);

class BartScoringResult {
  const BartScoringResult(this.indicators, this.score, this.breakdown);
  final BartIndicators indicators;
  final GameScore score;
  final List<ScoreBreakdownLine> breakdown;
}

class IstScoringResult {
  const IstScoringResult(this.indicators, this.score, this.breakdown);
  final IstIndicators indicators;
  final GameScore score;
  final List<ScoreBreakdownLine> breakdown;
}

/// Barème BART — miroir de `BartScoringService`.
class BartScoring {
  const BartScoring();

  BartScoringResult score({
    required String sessionId,
    required BartMetrics metrics,
  }) {
    final points = BartConfig.explosionPoints(sessionId);

    final test =
        <({int pumps, bool collected, int explosionPoint, int earned})>[];
    for (final balloon in metrics.balloons) {
      final explosionPoint = points[balloon.balloonIndex];
      final collected = balloon.outcome == BartBalloonOutcome.collected;
      // Rejeu : une issue impossible est un payload falsifié, rejeté comme côté
      // serveur (HTTP 400) plutôt que noté.
      if (!collected && balloon.pumpCount != explosionPoint) {
        throw ArgumentError(
          'Ballon ${balloon.balloonIndex} : éclatement incompatible',
        );
      }
      if (collected && balloon.pumpCount >= explosionPoint) {
        throw ArgumentError(
          'Ballon ${balloon.balloonIndex} : collecte impossible',
        );
      }
      if (balloon.phase != BartPhase.test) continue;
      test.add((
        pumps: balloon.pumpCount,
        collected: collected,
        explosionPoint: explosionPoint,
        earned: collected ? balloon.pumpCount * BartConfig.pointsPerPump : 0,
      ));
    }

    final collectedPumps = <int>[];
    var totalEarnings = 0;
    var explosions = 0;
    for (final b in test) {
      totalEarnings += b.earned;
      if (b.collected) {
        collectedPumps.add(b.pumps);
      } else {
        explosions++;
      }
    }

    final optimalPumps = BartConfig.optimalFixedPumps();
    var evOptimal = 0;
    for (final b in test) {
      if (b.explosionPoint > optimalPumps) {
        evOptimal += optimalPumps * BartConfig.pointsPerPump;
      }
    }

    final afterExplosion = <int>[];
    final afterCollect = <int>[];
    for (var i = 0; i + 1 < test.length; i++) {
      (test[i].collected ? afterCollect : afterExplosion).add(
        test[i + 1].pumps,
      );
    }

    final intervals = <int>[];
    for (final balloon in metrics.balloons) {
      if (balloon.phase != BartPhase.test) continue;
      final stamps = balloon.pumpTimestampsMs;
      for (var i = 1; i < stamps.length; i++) {
        intervals.add(stamps[i] - stamps[i - 1]);
      }
    }
    final medianInterval = _medianOrNull(intervals);

    final issues = <String>[
      if (!metrics.sessionCompleted) 'INCOMPLETE',
      if (metrics.interrupted) 'INTERRUPTED',
      if (metrics.backgroundEventCount > 0) 'BACKGROUND',
      if (metrics.focusLossCount > 0) 'FOCUS_LOSS',
      if (test.isNotEmpty &&
          test.every((b) => b.pumps <= BartProvisionalRules.nonEngagedMaxPumps))
        'NON_ENGAGED',
      if (medianInterval != null &&
          medianInterval < BartProvisionalRules.minMedianInterPumpMs)
        'IMPLAUSIBLE_TIMING',
      if (evOptimal == 0) 'DEGENERATE_SEQUENCE',
    ];

    final efficiency = BartProvisionalRules.efficiency(
      totalEarnings,
      evOptimal,
    );
    final indicators = BartIndicators(
      sessionValid: issues.isEmpty,
      validityIssues: issues,
      testBalloonCount: test.length,
      collectedCount: collectedPumps.length,
      explosionCount: explosions,
      adjustedAveragePumps: _meanOrNull(collectedPumps),
      totalEarnings: totalEarnings,
      evOptimalEarnings: evOptimal,
      optimalFixedPumps: optimalPumps,
      efficiencyPercent: efficiency,
      meanPumpsAfterExplosion: _meanOrNull(afterExplosion),
      meanPumpsAfterCollect: _meanOrNull(afterCollect),
      medianInterPumpIntervalMs: medianInterval,
    );
    final score = _score(
      efficiency,
      BartProvisionalRules.maxPoints,
      BartProvisionalRules.descriptiveLevel,
    );
    return BartScoringResult(indicators, score, breakdown(indicators, score));
  }

  /// Miroir de `ScoreBreakdownService.bart`.
  static List<ScoreBreakdownLine> breakdown(
    BartIndicators r,
    GameScore score,
  ) => [
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.note,
      label:
          'Score provisoire = gains / gains de la stratégie fixe optimale ('
          '${r.optimalFixedPumps} pompes par ballon) sur les mêmes ballons, '
          'plafonné à 100, arrondi half-up une seule fois. L\'appétence au risque '
          'est un trait descriptif : ni haute ni basse n\'est meilleure.',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Gains / benchmark',
      detail: '${r.totalEarnings} / ${r.evOptimalEarnings} pts',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Ballons collectés / éclatés',
      detail: '${r.collectedCount} / ${r.explosionCount}',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Pompes moyennes ajustées (descriptif)',
      detail: r.adjustedAveragePumps?.toString() ?? '—',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Validité technique',
      detail: r.sessionValid ? 'valide' : r.validityIssues.join(', '),
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.total,
      label: 'Score descriptif',
      points: score.rawPoints,
      maxPoints: score.maxPoints,
    ),
  ];
}

/// P(correct) exact sous la loi de génération — miroir de `IstPosteriorModel`.
class IstPosterior {
  IstPosterior._();

  static final List<List<double>> _binomial = _pascal(IstConfig.boxCount);

  static double pCorrect(int blueSeen, int orangeSeen, IstColor chosen) {
    final opened = blueSeen + orangeSeen;
    final remaining = IstConfig.boxCount - opened;
    final prior = IstProvisionalRules.blueCountPrior();
    var favourable = 0.0;
    var total = 0.0;
    for (var k = 0; k <= IstConfig.boxCount; k++) {
      if (prior[k] == 0.0) continue;
      final blueRemaining = k - blueSeen;
      if (blueRemaining < 0 || blueRemaining > remaining) continue;
      final weight =
          prior[k] *
          _binomial[remaining][blueRemaining] /
          _binomial[IstConfig.boxCount][k];
      total += weight;
      final majority = k >= IstConfig.majorityThreshold
          ? IstColor.blue
          : IstColor.orange;
      if (majority == chosen) favourable += weight;
    }
    if (total == 0.0) {
      throw ArgumentError(
        'Observation impossible sous la loi de génération des grilles',
      );
    }
    return favourable / total;
  }

  static List<List<double>> _pascal(int size) {
    final table = List.generate(
      size + 1,
      (_) => List<double>.filled(size + 1, 0),
    );
    for (var n = 0; n <= size; n++) {
      table[n][0] = 1.0;
      for (var k = 1; k <= n; k++) {
        table[n][k] =
            table[n - 1][k - 1] + (k <= n - 1 ? table[n - 1][k] : 0.0);
      }
    }
    return table;
  }
}

/// Barème IST — miroir de `IstScoringService`.
class IstScoring {
  const IstScoring();

  IstScoringResult score({
    required String sessionId,
    required IstMetrics metrics,
  }) {
    final layouts = IstConfig.generateLayouts(sessionId);

    final test =
        <
          ({
            IstCondition condition,
            bool correct,
            int boxes,
            double pCorrect,
            int points,
            int? confidence,
          })
        >[];
    for (final trial in metrics.trials) {
      final layout = layouts[trial.trialIndex];
      var blueSeen = 0;
      for (final opening in trial.openings) {
        if (layout.boxes[opening.boxIndex] == IstColor.blue) blueSeen++;
      }
      final opened = trial.openings.length;
      final correct = trial.chosenColor == layout.majorityColor;
      final pCorrect = round4(
        IstPosterior.pCorrect(blueSeen, opened - blueSeen, trial.chosenColor),
      );
      if (layout.slot.phase != IstPhase.test) continue;
      test.add((
        condition: layout.slot.condition,
        correct: correct,
        boxes: opened,
        pCorrect: pCorrect,
        points: IstConfig.trialPoints(layout.slot.condition, opened, correct),
        confidence: trial.confidence,
      ));
    }

    final correct = test.where((t) => t.correct).length;
    final accuracy = test.isEmpty ? 0.0 : correct / test.length;
    List<int> boxes(IstCondition c) => [
      for (final t in test)
        if (t.condition == c) t.boxes,
    ];
    List<double> pCorrects(IstCondition c) => [
      for (final t in test)
        if (t.condition == c) t.pCorrect,
    ];
    final boxesFixed = _meanOrZero(boxes(IstCondition.fixedWin));
    final boxesDecreasing = _meanOrZero(boxes(IstCondition.decreasingWin));
    final pCorrect = _meanOrZero([for (final t in test) t.pCorrect]);
    final earnings = test.fold<int>(0, (sum, t) => sum + t.points);
    final randomResponses = test
        .where(
          (t) => t.pCorrect <= IstProvisionalRules.randomResponseMaxPCorrect,
        )
        .length;

    final intervals = <int>[];
    for (final trial in metrics.trials) {
      if (trial.slot.phase != IstPhase.test) continue;
      int? previous;
      for (final opening in trial.openings) {
        if (previous != null) intervals.add(opening.timestampMs - previous);
        previous = opening.timestampMs;
      }
      if (previous != null) intervals.add(trial.decisionTimestampMs - previous);
    }
    final medianInterval = _medianOrNull(intervals);

    final issues = <String>[
      if (!metrics.sessionCompleted) 'INCOMPLETE',
      if (metrics.interrupted) 'INTERRUPTED',
      if (metrics.backgroundEventCount > 0) 'BACKGROUND',
      if (metrics.focusLossCount > 0) 'FOCUS_LOSS',
      if (test.isNotEmpty && test.every((t) => t.boxes == 0)) 'NON_ENGAGED',
      if (medianInterval != null &&
          medianInterval < IstProvisionalRules.minMedianInterActionMs)
        'IMPLAUSIBLE_TIMING',
      if (test.isNotEmpty &&
          randomResponses / test.length >
              IstProvisionalRules.maxRandomResponseRate)
        'RANDOM_RESPONSES',
    ];

    // Couche confiance : biais de calibration SEUL (miroir de MetacognitionService).
    var confidenceSum = 0.0;
    var confidentCorrect = 0;
    var confidenceCount = 0;
    for (final t in test) {
      final confidence = t.confidence;
      if (confidence == null) continue;
      confidenceSum += IstProvisionalRules.confidenceProbability(confidence);
      if (t.correct) confidentCorrect++;
      confidenceCount++;
    }
    final calibrationBias = confidenceCount == 0
        ? null
        : round4(
            confidenceSum / confidenceCount -
                confidentCorrect / confidenceCount,
          );

    final points = IstProvisionalRules.score(
      accuracy,
      pCorrect,
      boxesFixed,
      boxesDecreasing,
    );
    final indicators = IstIndicators(
      sessionValid: issues.isEmpty,
      validityIssues: issues,
      testTrialCount: test.length,
      correctCount: correct,
      accuracyPercent: round4(accuracy * 100.0),
      meanBoxesFixedWin: boxesFixed,
      meanBoxesDecreasingWin: boxesDecreasing,
      conditionDiscrimination: round4(boxesFixed - boxesDecreasing),
      meanPCorrectAtDecision: pCorrect,
      meanPCorrectFixedWin: _meanOrZero(pCorrects(IstCondition.fixedWin)),
      meanPCorrectDecreasingWin: _meanOrZero(
        pCorrects(IstCondition.decreasingWin),
      ),
      totalEarnings: earnings,
      randomResponseCount: randomResponses,
      medianInterActionIntervalMs: medianInterval,
      confidenceResponseCount: confidenceCount,
      calibrationBias: calibrationBias,
      provisionalScore: points,
    );
    final score = _score(
      points,
      IstProvisionalRules.maxPoints,
      IstProvisionalRules.descriptiveLevel,
    );
    return IstScoringResult(indicators, score, breakdown(indicators, score));
  }

  /// Miroir de `ScoreBreakdownService.ist`.
  static List<ScoreBreakdownLine> breakdown(
    IstIndicators r,
    GameScore score,
  ) => [
    const ScoreBreakdownLine(
      kind: ScoreBreakdownKind.note,
      label:
          'Score provisoire = 40 % exactitude + 40 % preuve détenue à la '
          'décision + 20 % ajustement de l\'échantillonnage à son coût, arrondi '
          'half-up une seule fois. Entraînement et confiance sont hors score.',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Décisions justes',
      detail: '${r.correctCount}/${r.testTrialCount} (${r.accuracyPercent} %)',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'P(correct) moyen à la décision',
      detail: '${r.meanPCorrectAtDecision}',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Cases ouvertes gain fixe / décroissant',
      detail: '${r.meanBoxesFixedWin} / ${r.meanBoxesDecreasingWin}',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Biais de calibration (descriptif)',
      detail: r.calibrationBias?.toString() ?? '—',
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.info,
      label: 'Validité technique',
      detail: r.sessionValid ? 'valide' : r.validityIssues.join(', '),
    ),
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.total,
      label: 'Score descriptif',
      points: score.rawPoints,
      maxPoints: score.maxPoints,
    ),
  ];
}
