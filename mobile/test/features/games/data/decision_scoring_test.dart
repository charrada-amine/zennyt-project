import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/decision_scoring.dart';
import 'package:zennyt/features/games/domain/config/decision_config.dart';
import 'package:zennyt/features/games/domain/config/decision_provisional_rules.dart';
import 'package:zennyt/features/games/domain/decision_scenario_catalog.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';

/// Parité mock ⇄ backend du barème « Je Décide » (miroir de DecisionScoringTest.java).
/// Catalogue de test injecté (aucun contenu de scénario de production).
class _MapCatalog implements DecisionScenarioCatalog {
  final Map<String, DecisionScenarioItem> _items = {};

  void put(String id, DecisionDimension dim, DecisionItemFormat fmt, OptionQuality q) {
    _items[id] = DecisionScenarioItem(
      itemId: id,
      dimension: dim,
      format: fmt,
      optionQualities: {'opt': q},
    );
  }

  @override
  DecisionScenarioItem? item(String itemId) => _items[itemId];

  @override
  bool get isEmpty => _items.isEmpty;
}

void main() {
  DecisionMetrics buildAllDims(OptionQuality q, {int responseTimeMs = 15000, _MapCatalog? into}) {
    final catalog = into ?? _MapCatalog();
    final items = <DecisionItemResponse>[];
    for (final d in DecisionDimension.values) {
      for (var i = 1; i <= DecisionConfig.itemsPerDimension; i++) {
        final id = '${d.wire}-$i';
        catalog.put(id, d, DecisionItemFormat.standard, q);
        items.add(DecisionItemResponse(
          itemId: id,
          dimension: d,
          selectedOptionId: 'opt',
          responseTimeMs: responseTimeMs,
        ));
      }
    }
    return DecisionMetrics(items: items, sessionLanguage: 'en');
  }

  test('6 items OPTIMAL par dimension → SCW 100, niveau Élevé', () {
    final catalog = _MapCatalog();
    final metrics = buildAllDims(OptionQuality.optimal, into: catalog);
    final score = DecisionScoring(catalog).score(metrics, 0.0);
    expect(score.rawPoints, 100);
    expect(score.maxPoints, 100);
    expect(score.level, 'Élevé');
  });

  test('exemple validé de la fiche : raw=60 → SCW ≈ 66,7 → Normal', () {
    final dims = {
      DecisionDimension.ii: 12,
      DecisionDimension.er: 9,
      DecisionDimension.dt: 15,
      DecisionDimension.cs: 14,
      DecisionDimension.re: 10,
    };
    final scw = DecisionProvisionalRules.scw(dims);
    expect(scw, closeTo(66.7, 0.1));
    expect(DecisionProvisionalRules.levelForScw(scw), 'Normal');
  });

  test('DT : correct+rapide → 3 · correct+lent → 2 · incorrect → qualité', () {
    const svc = DecisionScoring(EmptyDecisionScenarioCatalog());
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 1000, 1.0, 0), 3);
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 6000, 1.0, 0), 2);
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.partial, 500, 1.0, 0), 1);
  });

  test('DT langue : même latence 6000 ms → 2 en en, 3 en fr', () {
    const svc = DecisionScoring(EmptyDecisionScenarioCatalog());
    expect(DecisionConfig.providedLanguageMultiplier('fr'), 1.20);
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 6000, 1.00, 0), 2);
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 6000, 1.20, 0), 3);
  });

  test('DT calibrage : un appareil lent ne fait pas basculer 3 → 2', () {
    const svc = DecisionScoring(EmptyDecisionScenarioCatalog());
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 5400, 1.0, 0), 2);
    expect(svc.scoreItem(DecisionItemFormat.temporalDecision, OptionQuality.optimal, 5400, 1.0, 800), 3);
  });

  test('imputation : ≤ 2 manquants → moyenne du bloc · > 2 → non exploitable', () {
    expect(DecisionConfig.imputedDimensionScore([3, 3, 3, 3]), 18);
    expect(DecisionConfig.imputedDimensionScore([2, 2, 3, 1]), 12);
    expect(DecisionConfig.imputedDimensionScore([3, 3, 3]), isNull);
  });

  test('bornes de niveau (seul ≥ 75 vient de la fiche)', () {
    expect(DecisionProvisionalRules.levelForScw(80), 'Élevé');
    expect(DecisionProvisionalRules.levelForScw(66), 'Normal');
    expect(DecisionProvisionalRules.levelForScw(50), 'Borderline');
    expect(DecisionProvisionalRules.levelForScw(30), 'Fragile');
  });
}
