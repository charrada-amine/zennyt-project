/// Couche PROVISOIRE de l'IST — miroir de `IstProvisionalRules.java`.
/// Aucune de ces valeurs n'est validée par le psychologue référent.
class IstProvisionalRules {
  IstProvisionalRules._();

  static const maxPoints = 100;
  static const descriptiveLevel = 'Descriptive — provisional';

  /// Loi de génération — SOURCE UNIQUE du générateur ET de l'a priori de
  /// P(correct). La couleur majoritaire occupe 13 à 19 cases.
  static const majorityCountMin = 13;
  static const majorityCountMax = 19;
  static const blueCountMin = 25 - majorityCountMax;
  static const blueCountMax = majorityCountMax;

  static List<double> blueCountPrior() {
    final prior = List<double>.filled(26, 0);
    const support = blueCountMax - blueCountMin + 1;
    for (var k = blueCountMin; k <= blueCountMax; k++) {
      prior[k] = 1.0 / support;
    }
    return prior;
  }

  static const accuracyWeight = 0.4;
  static const evidenceWeight = 0.4;
  static const discriminationWeight = 0.2;
  static const discriminationReferenceBoxes = 5.0;

  static int score(
    double accuracy,
    double meanPCorrect,
    double boxesFixedWin,
    double boxesDecreasingWin,
  ) {
    final evidence = _clamp01((meanPCorrect - 0.5) / 0.5);
    final discrimination = _clamp01(
      (boxesFixedWin - boxesDecreasingWin) / discriminationReferenceBoxes,
    );
    final weighted = accuracyWeight * _clamp01(accuracy) +
        evidenceWeight * evidence +
        discriminationWeight * discrimination;
    final points = (100.0 * weighted + 0.5).floor();
    return points > maxPoints ? maxPoints : points;
  }

  static const minMedianInterActionMs = 80.0;
  static const randomResponseMaxPCorrect = 0.1;
  static const maxRandomResponseRate = 0.3;

  static const confidenceMin = 1;
  static const confidenceMax = 4;

  /// 1 = au hasard (0,5) · 2 = plutôt sûr (2/3) · 3 = sûr (5/6) · 4 = certain (1).
  static double confidenceProbability(int confidence) =>
      0.5 + 0.5 * (confidence - confidenceMin) / (confidenceMax - confidenceMin);

  static double _clamp01(double value) =>
      value < 0 ? 0 : (value > 1 ? 1 : value);
}
