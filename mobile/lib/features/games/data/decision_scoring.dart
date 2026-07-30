import '../domain/config/decision_config.dart';
import '../domain/config/decision_provisional_rules.dart';
import '../domain/decision_scenario_catalog.dart';
import '../domain/entities/decision_metrics.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/score_breakdown.dart';

/// Barème de « Je Décide » — miroir EXACT de `DecisionScoringService.java` (backend).
///
/// Deux couches strictement séparées : MOTEUR (`DecisionConfig`, agrégation /18 →
/// /90, règle DT à double ajustement, imputation) + PROVISOIRE
/// (`DecisionProvisionalRules` : qualité, poids SCW, bornes, CS, multiplicateurs).
/// Le contenu des scénarios provient d'un `DecisionScenarioCatalog` injecté —
/// jamais codé ici. Tant que le catalogue est vide, ce barème n'est pas jouable
/// (parité backend : `DECISION_CORE.isPlayable()=false`).
class DecisionScoring {
  const DecisionScoring(this.catalog);

  final DecisionScenarioCatalog catalog;

  /// Score agrégé du mini-jeu : SCW /100 + niveau (miroir de `score`).
  GameScore score(DecisionMetrics m, double calibrationOffsetMs) {
    final dims = _computeDimensions(m, calibrationOffsetMs);
    final scwValue = _scw(dims);
    final scw = scwValue.round();
    return GameScore(
      rawPoints: scw,
      maxPoints: 100,
      normalized: scw.toDouble(),
      level: DecisionProvisionalRules.levelForScw(scw.toDouble()),
    );
  }

  /// Détail du score : une ligne par dimension /18, puis brut /90, puis SCW /100.
  List<ScoreBreakdownLine> breakdown(DecisionMetrics m, GameScore score,
      {double calibrationOffsetMs = 0.0}) {
    final dims = _computeDimensions(m, calibrationOffsetMs);
    final raw = dims.values
        .where((o) => o.score != null)
        .fold<int>(0, (s, o) => s + o.score!);
    final lines = <ScoreBreakdownLine>[
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label: 'Chaque dimension est notée /18 (6 items × 3) ; brut = somme /90 ; '
            'SCW = score composite standardisé pondéré /100 (poids provisoires).',
      ),
    ];
    for (final d in DecisionConfig.dimensions) {
      final o = dims[d]!;
      if (o.score != null) {
        lines.add(ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: d.wire,
          detail: '${o.answeredCount} items',
          points: o.score,
          maxPoints: DecisionConfig.dimensionMax,
        ));
      } else {
        lines.add(ScoreBreakdownLine(
          kind: ScoreBreakdownKind.info,
          label: d.wire,
          detail: 'bloc non exploitable (> 2 items manquants)',
        ));
      }
    }
    lines.add(ScoreBreakdownLine(
      kind: ScoreBreakdownKind.subtotal,
      label: 'Brut',
      points: raw,
      maxPoints: DecisionConfig.rawMax,
    ));
    lines.add(ScoreBreakdownLine(
      kind: ScoreBreakdownKind.total,
      label: 'SCW',
      points: score.rawPoints,
      maxPoints: score.maxPoints,
    ));
    return lines;
  }

  Map<DecisionDimension, _DimensionOutcome> _computeDimensions(
      DecisionMetrics m, double calibrationOffsetMs) {
    final languageMultiplier = _resolveLanguageMultiplier(m.sessionLanguage);
    final byDimension = <DecisionDimension, List<int>>{
      for (final d in DecisionDimension.values) d: <int>[],
    };
    final answeredCount = <DecisionDimension, int>{
      for (final d in DecisionDimension.values) d: 0,
    };

    for (final r in m.items) {
      if (!r.answered) continue; // item manquant → imputation
      final item = catalog.item(r.itemId);
      if (item == null) {
        throw ArgumentError(
            'Item absent du catalogue « Je Décide » : ${r.itemId}');
      }
      final quality = item.qualityOf(r.selectedOptionId ?? '');
      final points = scoreItem(item.format, quality, r.responseTimeMs,
          languageMultiplier, calibrationOffsetMs);
      final dim = item.dimension; // catalogue autoritaire
      byDimension[dim]!.add(points);
      answeredCount[dim] = answeredCount[dim]! + 1;
    }

    final out = <DecisionDimension, _DimensionOutcome>{};
    for (final d in DecisionDimension.values) {
      out[d] = _DimensionOutcome(
        DecisionConfig.imputedDimensionScore(byDimension[d]!),
        answeredCount[d]!,
      );
    }
    return out;
  }

  /// Note d'UN item /3. DT : correct+rapide → 3 · correct+lent → 2 · incorrect →
  /// score de qualité de l'option. STANDARD/CS : score de qualité de l'option.
  int scoreItem(DecisionItemFormat format, OptionQuality quality,
      int responseTimeMs, double languageMultiplier, double calibrationOffsetMs) {
    if (format == DecisionItemFormat.temporalDecision) {
      final correct = quality == OptionQuality.optimal;
      if (!correct) return DecisionProvisionalRules.optionScore(quality);
      final limitMs = DecisionConfig.dtEffectiveLimitMs(
          languageMultiplier, calibrationOffsetMs);
      final fast = responseTimeMs < DecisionConfig.dtFastThresholdRatio * limitMs;
      return fast ? DecisionConfig.dtFastPoints : DecisionConfig.dtSlowPoints;
    }
    return DecisionProvisionalRules.optionScore(quality);
  }

  double _scw(Map<DecisionDimension, _DimensionOutcome> dims) {
    final exploitable = <DecisionDimension, int>{};
    dims.forEach((d, o) {
      if (o.score != null) exploitable[d] = o.score!;
    });
    return DecisionProvisionalRules.scw(exploitable);
  }

  double _resolveLanguageMultiplier(String? code) {
    return DecisionConfig.providedLanguageMultiplier(code) ??
        DecisionProvisionalRules.provisionalLanguageMultiplier(code) ??
        DecisionProvisionalRules.languageFallbackMultiplier; // fallback tracé (ex. ar)
  }
}

class _DimensionOutcome {
  const _DimensionOutcome(this.score, this.answeredCount);
  final int? score;
  final int answeredCount;
}
