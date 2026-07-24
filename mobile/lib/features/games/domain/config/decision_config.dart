import '../entities/decision_metrics.dart';

/// Configuration MOTEUR (définitive) de « Je Décide » — miroir EXACT de
/// `DecisionConfig.java` (backend). Ne contient QUE des valeurs de la fiche
/// « JE DÉCIDE » ; aucune valeur provisoire (celles-ci vivent dans
/// `decision_provisional_rules.dart`).
class DecisionConfig {
  DecisionConfig._();

  // Structure du test (fiche).
  static const int capabilitiesCount = 5;
  static const int itemsPerDimension = 6;
  static const int totalItems = 30;
  static const int itemScoreMin = 0;
  static const int itemScoreMax = 3;
  static const int trainingItemsCount = 3;
  static const int maxVignetteReadTimeS = 45;
  static const int responseTimeMinS = 10;
  static const int responseTimeMaxS = 30;

  // Agrégation.
  static const int dimensionMax = itemsPerDimension * itemScoreMax; // 18
  static const int rawMax = capabilitiesCount * dimensionMax; // 90

  // Règle DT (seule dimension dont le score dépend du temps).
  static const int dtTimeLimitBaseS = 7;
  static const double dtFastThresholdRatio = 0.75;
  static const int dtFastPoints = 3;
  static const int dtSlowPoints = 2;

  /// Multiplicateurs linguistiques FOURNIS par la fiche (définitifs).
  static const Map<String, double> languageMultipliers = {
    'en': 1.00,
    'fr': 1.20,
    'de': 1.25,
  };

  static double? providedLanguageMultiplier(String? code) =>
      code == null ? null : languageMultipliers[code.trim().toLowerCase()];

  /// Temps imparti EFFECTIF d'un item DT (ms) : base × mult. langue + offset calibrage.
  static double dtEffectiveLimitMs(
    double languageMultiplier,
    double calibrationOffsetMs,
  ) {
    final offset = calibrationOffsetMs < 0 ? 0.0 : calibrationOffsetMs;
    return dtTimeLimitBaseS * 1000.0 * languageMultiplier + offset;
  }

  // Imputation.
  static const int maxImputableMissing = 2;

  /// Score /18 d'une dimension après imputation, ou `null` si bloc non exploitable
  /// (> 2 items manquants). ≤ 2 manquants → moyenne du bloc × 6 (arrondie).
  static int? imputedDimensionScore(List<int> answeredItemScores) {
    final answered = answeredItemScores.length;
    final missing = itemsPerDimension - answered;
    if (missing < 0) {
      throw ArgumentError('Trop d\'items pour une dimension : $answered');
    }
    if (missing > maxImputableMissing || answered == 0) {
      return null; // bloc non exploitable / aucun item
    }
    final mean =
        answeredItemScores.reduce((a, b) => a + b) / answered;
    return (mean * itemsPerDimension).round();
  }

  static const List<DecisionDimension> dimensions = DecisionDimension.values;
}
