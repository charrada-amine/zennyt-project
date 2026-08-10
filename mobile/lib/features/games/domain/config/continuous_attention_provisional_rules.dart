/// Couche provisoire de cotation « Je continue ».
///
/// Les indicateurs descriptifs restent indépendants de cette règle et ne
/// doivent jamais devenir une interprétation clinique, un percentile ou un
/// classement.
class ContinuousAttentionProvisionalRules {
  const ContinuousAttentionProvisionalRules._();

  static const neutralLevel = 'Descriptive — provisional';

  // PROVISOIRE — non validé par le psychologue
  static int scoreFromPhaseCounts({
    required int xHits,
    required int xTargets,
    required int xCorrectRejections,
    required int xNonTargets,
    required int axHits,
    required int axTargets,
    required int axCorrectRejections,
    required int axNonTargets,
  }) {
    if (xTargets <= 0 ||
        xNonTargets <= 0 ||
        axTargets <= 0 ||
        axNonTargets <= 0) {
      return 0;
    }
    // Calcul rationnel exact : aucune approximation binaire ne peut changer
    // l'arrondi positif half-up d'une valeur située exactement à x.5.
    final denominator = xTargets * xNonTargets * axTargets * axNonTargets;
    final sum =
        (xHits * xNonTargets * axTargets * axNonTargets) +
        (xCorrectRejections * xTargets * axTargets * axNonTargets) +
        (axHits * xTargets * xNonTargets * axNonTargets) +
        (axCorrectRejections * xTargets * xNonTargets * axTargets);
    final numerator = 25 * sum;
    return ((2 * numerator + denominator) ~/ (2 * denominator)).clamp(0, 100);
  }
}
