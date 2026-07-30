import '../decision_scenario_catalog.dart';
import '../entities/decision_metrics.dart';
import 'decision_config.dart';

/// COUCHE PROVISOIRE — miroir EXACT de `DecisionProvisionalRules.java` (backend).
/// Toutes les règles déduites (non fournies par le psychologue) sont isolées ici,
/// chaque constante commentée `// PROVISOIRE`. Le moteur (`decision_scoring.dart`)
/// ne code jamais ces valeurs en dur : il les lit d'ici. Les remplacer ne demande
/// aucune modification du moteur.
class DecisionProvisionalRules {
  DecisionProvisionalRules._();

  // a) Étiquetage qualité → score (barème 0..3 = échelle de la fiche).
  static int optionScore(OptionQuality quality) => quality.points; // PROVISOIRE (étiquetage)

  // b) Poids SCW = 1.0 pour les 5 dimensions. PROVISOIRE (poids égaux).
  static const Map<DecisionDimension, double> scwWeights = {
    DecisionDimension.ii: 1.0,
    DecisionDimension.er: 1.0,
    DecisionDimension.dt: 1.0,
    DecisionDimension.cs: 1.0,
    DecisionDimension.re: 1.0,
  };

  /// SCW /100 = (Σ dim×poids)/(18×Σ poids)×100 sur les dimensions exploitables.
  static double scw(Map<DecisionDimension, int> dimensionScores) {
    double numerator = 0;
    double weightSum = 0;
    dimensionScores.forEach((d, score) {
      final w = scwWeights[d] ?? 1.0;
      numerator += score * w;
      weightSum += w;
    });
    if (weightSum == 0) return 0;
    return numerator / (DecisionConfig.dimensionMax * weightSum) * 100.0;
  }

  // c) Bornes de niveau — seul ≥ 75 vient de la fiche.
  static const int levelHighMin = 75; // ← fiche
  static const int levelNormalMin = 60; // PROVISOIRE
  static const int levelBorderlineMin = 45; // PROVISOIRE

  static String levelForScw(double scwValue) {
    if (scwValue >= levelHighMin) return 'Élevé';
    if (scwValue >= levelNormalMin) return 'Normal';
    if (scwValue >= levelBorderlineMin) return 'Borderline';
    return 'Fragile';
  }

  // d) Règle CS — note dérivée de la cohérence de la paire. PROVISOIRE.
  static OptionQuality coherenceQuality(CoherenceLevel level) {
    switch (level) {
      case CoherenceLevel.coherent:
        return OptionQuality.optimal;
      case CoherenceLevel.partial:
        return OptionQuality.satisfactory;
      case CoherenceLevel.contradictory:
        return OptionQuality.deficient;
    }
  }

  // e) Multiplicateurs es/it/pt + fallback ar. PROVISOIRE (estimations).
  static const Map<String, double> provisionalLanguageMultipliers = {
    'es': 1.22,
    'it': 1.18,
    'pt': 1.22,
  };
  static const double languageFallbackMultiplier = 1.20; // PROVISOIRE

  static double? provisionalLanguageMultiplier(String? code) => code == null
      ? null
      : provisionalLanguageMultipliers[code.trim().toLowerCase()];

  // Seuils « bas/élevé » par dimension (déclencheurs d'interprétation). PROVISOIRE.
  static const double dimensionHighRatio = 0.66;
  static const double dimensionLowRatio = 0.34;

  static bool isDimensionHigh(int dimensionScore) =>
      dimensionScore / DecisionConfig.dimensionMax >= dimensionHighRatio;

  static bool isDimensionLow(int dimensionScore) =>
      dimensionScore / DecisionConfig.dimensionMax <= dimensionLowRatio;

  // Seuils de qualité de session. PROVISOIRE (renforcés en non supervisé).
  static const double minPlausibleAvgTimeMs = 1500.0;
  static const double maxImpulsiveRate = 0.30;
  static const double maxRandomResponseRate = 0.30;
  static const double maxDeviceLatencyOffsetMs = 100.0;
  static const double unsupervisedStrictnessFactor = 1.25;
}

/// Niveau de cohérence d'une paire CS (miroir de CoherenceLevel).
enum CoherenceLevel { coherent, partial, contradictory }
