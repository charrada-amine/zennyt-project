// Parité mock ⇄ backend pour BART et IST.
//
// Les valeurs attendues ont été calculées par le code Java
// (BartScoringService, IstScoringService, IstPosteriorModel) pour la session de
// référence 5b6b3a43-9d2f-4c7e-8a51-0c2e7f1d9a10, avec les mêmes joueurs simulés
// que `DecisionBehavioralTestFixtures.java`. Si l'un de ces tests échoue, le mock
// et le serveur ne notent plus pareil : corriger le côté fautif, jamais la valeur.
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/decision_behavioral_scoring.dart';
import 'package:zennyt/features/games/domain/config/bart_config.dart';
import 'package:zennyt/features/games/domain/config/ist_config.dart';
import 'package:zennyt/features/games/domain/entities/bart_metrics.dart';
import 'package:zennyt/features/games/domain/entities/ist_metrics.dart';

const sessionId = '5b6b3a43-9d2f-4c7e-8a51-0c2e7f1d9a10';

/// Miroir de `DecisionBehavioralTestFixtures.bartFixedStrategy`.
BartMetrics bartFixedStrategy(int target, int intervalMs) {
  final points = BartConfig.explosionPoints(sessionId);
  return BartMetrics(
    balloons: [
      for (var i = 0; i < BartConfig.totalBalloonCount; i++)
        () {
          final explodes = target >= points[i];
          final pumps = explodes ? points[i] : target;
          return BartBalloonMetric(
            balloonIndex: i,
            pumpCount: pumps,
            outcome: explodes ? BartBalloonOutcome.exploded : BartBalloonOutcome.collected,
            pumpTimestampsMs: [for (var p = 1; p <= pumps; p++) p * intervalMs],
            collectTimestampMs: explodes ? null : (pumps + 1) * intervalMs,
          );
        }(),
    ],
    interrupted: false,
    backgroundEventCount: 0,
    focusLossCount: 0,
  );
}

/// Miroir de `DecisionBehavioralTestFixtures.istStrategy`.
IstMetrics istStrategy(int boxesFixed, int boxesDecreasing, int? confidence, int intervalMs) {
  final layouts = IstConfig.generateLayouts(sessionId);
  return IstMetrics(
    trials: [
      for (final layout in layouts)
        () {
          final n = layout.slot.condition == IstCondition.fixedWin ? boxesFixed : boxesDecreasing;
          var blue = 0;
          for (var b = 0; b < n; b++) {
            if (layout.boxes[b] == IstColor.blue) blue++;
          }
          return IstTrialMetric(
            trialIndex: layout.slot.trialIndex,
            openings: [
              for (var b = 0; b < n; b++) IstBoxOpening(boxIndex: b, timestampMs: (b + 1) * intervalMs),
            ],
            chosenColor: blue * 2 >= n ? IstColor.blue : IstColor.orange,
            decisionTimestampMs: (n + 1) * intervalMs,
            confidence: confidence,
          );
        }(),
    ],
    interrupted: false,
    backgroundEventCount: 0,
    focusLossCount: 0,
  );
}

void main() {
  group('générateurs — identiques au Java', () {
    test('points d\'éclatement BART', () {
      expect(BartConfig.explosionPoints(sessionId), [
        42, 40, 77, 99, 24, 67, 14, 92, 117, 56, 75, 112, 118, 101, 90, 109,
        55, 103, 42, 36, 54, 18, 34, 30, 22, 89, 20, 71, 37, 18, 14, 69,
      ]);
      expect(BartConfig.optimalFixedPumps(), 64);
    });

    test('grilles IST', () {
      final layouts = IstConfig.generateLayouts(sessionId);
      expect(layouts.map((l) => l.blueCount).toList(), [
        12, 17, 18, 18, 10, 6, 15, 12, 16, 12, 11, 17, 16, 14, 11, 15, 7, 17, 19, 15, 13, 11,
      ]);
      expect(
        layouts[2].boxes.map((c) => c == IstColor.blue ? 'B' : 'O').join(),
        'BBBBBOOBBBOBBBBBBBBOBOOBO',
      );
    });

    test('P(correct) exact', () {
      expect(IstPosterior.pCorrect(3, 1, IstColor.blue), 0.7678684376976598);
      expect(IstPosterior.pCorrect(5, 2, IstColor.blue), 0.8658594216497484);
      expect(IstPosterior.pCorrect(1, 0, IstColor.blue), 0.6400000000000001);
    });
  });

  group('BART — mêmes rapports que BartScoringService', () {
    // total | benchmark | efficience | pompes ajustées | éclatements |
    // après éclatement | après collecte | intervalle médian
    const expected = {
      10: (300, 960, 31, 10.0, 0, null, 10.0, 200.0),
      40: (760, 960, 79, 40.0, 11, 32.5455, 34.9444, 200.0),
      64: (960, 960, 100, 64.0, 15, 44.9333, 49.7143, 200.0),
      120: (0, 960, 0, null, 30, 61.5862, null, 200.0),
    };
    expected.forEach((target, e) {
      test('stratégie fixe $target pompes', () {
        final r = const BartScoring().score(sessionId: sessionId, metrics: bartFixedStrategy(target, 200));
        final i = r.indicators;
        expect(i.totalEarnings, e.$1);
        expect(i.evOptimalEarnings, e.$2);
        expect(i.efficiencyPercent, e.$3);
        expect(r.score.rawPoints, e.$3);
        expect(i.adjustedAveragePumps, e.$4);
        expect(i.explosionCount, e.$5);
        expect(i.meanPumpsAfterExplosion, e.$6);
        expect(i.meanPumpsAfterCollect, e.$7);
        expect(i.medianInterPumpIntervalMs, e.$8);
        expect(i.validityIssues, isEmpty);
      });
    });

    test('une collecte au-delà du point serveur est rejetée', () {
      final valid = bartFixedStrategy(64, 200);
      final point = BartConfig.explosionPoints(sessionId).first;
      final forged = BartMetrics(
        balloons: [
          BartBalloonMetric(
            balloonIndex: 0,
            pumpCount: point,
            outcome: BartBalloonOutcome.collected,
            pumpTimestampsMs: [for (var p = 1; p <= point; p++) p * 200],
            collectTimestampMs: (point + 1) * 200,
          ),
          ...valid.balloons.skip(1),
        ],
        interrupted: false,
        backgroundEventCount: 0,
        focusLossCount: 0,
      );
      expect(
        () => const BartScoring().score(sessionId: sessionId, metrics: forged),
        throwsArgumentError,
      );
    });

    test('non engagé et cadence inhumaine : invalides', () {
      expect(
        const BartScoring().score(sessionId: sessionId, metrics: bartFixedStrategy(0, 200))
            .indicators.validityIssues,
        contains('NON_ENGAGED'),
      );
      expect(
        const BartScoring().score(sessionId: sessionId, metrics: bartFixedStrategy(40, 5))
            .indicators.validityIssues,
        contains('IMPLAUSIBLE_TIMING'),
      );
    });
  });

  group('IST — mêmes rapports que IstScoringService', () {
    // justes | exactitude | P moyen | P FW | P DW | discrimination | gains |
    // aléatoires | biais | score
    const expected = {
      (25, 15): (19, 95.0, 0.9246, 1.0, 0.8492, 10.0, 1800, 0, -0.1167, 92),
      (6, 3): (13, 65.0, 0.7528, 0.7986, 0.707, 3.0, 1440, 0, 0.1833, 58),
      (10, 10): (15, 75.0, 0.7809, 0.838, 0.7237, 0.0, 1400, 0, 0.0833, 52),
      (3, 1): (11, 55.0, 0.7052, 0.7705, 0.64, 2.0, 900, 0, 0.2833, 46),
    };
    expected.forEach((cfg, e) {
      test('ouvre ${cfg.$1} (gain fixe) / ${cfg.$2} (gain décroissant)', () {
        final r = const IstScoring().score(
          sessionId: sessionId,
          metrics: istStrategy(cfg.$1, cfg.$2, 3, 300),
        );
        final i = r.indicators;
        expect(i.correctCount, e.$1);
        expect(i.accuracyPercent, e.$2);
        expect(i.meanPCorrectAtDecision, e.$3);
        expect(i.meanPCorrectFixedWin, e.$4);
        expect(i.meanPCorrectDecreasingWin, e.$5);
        expect(i.conditionDiscrimination, e.$6);
        expect(i.totalEarnings, e.$7);
        expect(i.randomResponseCount, e.$8);
        expect(i.calibrationBias, e.$9);
        expect(i.provisionalScore, e.$10);
        expect(r.score.rawPoints, e.$10);
        expect(i.validityIssues, isEmpty);
      });
    });

    test('la sensibilité métacognitive n\'existe pas dans les indicateurs', () {
      final r = const IstScoring().score(sessionId: sessionId, metrics: istStrategy(25, 15, 4, 300));
      expect(r.indicators.calibrationBias, isNotNull);
      expect(r.breakdown.map((l) => l.label), isNot(contains(contains('AUROC'))));
    });
  });

  test('JSON émis : jamais de point d\'éclatement, de couleur révélée ni de score', () {
    final bart = bartFixedStrategy(64, 200).toJson();
    final ist = istStrategy(25, 15, 3, 300).toJson();
    expect(bart['protocolVersion'], 'BART_LEJUEZ_V1');
    expect((bart['bartBalloons'] as List).first, isNot(contains('explosionPoint')));
    expect(ist['protocolVersion'], 'IST_CLARK_V1');
    final opening = ((ist['istTrials'] as List).first['openings'] as List).first as Map;
    expect(opening.keys, unorderedEquals(['boxIndex', 'timestampMs']));
    expect(bart.containsKey('score') || ist.containsKey('score'), isFalse);
  });
}
