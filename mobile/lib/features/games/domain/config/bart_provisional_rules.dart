/// Couche PROVISOIRE du BART — miroir de `BartProvisionalRules.java`.
/// Aucune de ces valeurs n'est validée par le psychologue référent.
class BartProvisionalRules {
  BartProvisionalRules._();

  static const maxPoints = 100;
  static const descriptiveLevel = 'Descriptive — provisional';

  /// PROVISOIRE — intervalle médian minimal entre deux pompes.
  static const minMedianInterPumpMs = 60.0;

  /// PROVISOIRE — au plus ce nombre de pompes sur TOUS les ballons = non engagé.
  static const nonEngagedMaxPumps = 1;

  /// PROVISOIRE — efficience = gains / benchmark, arrondi half-up, plafond 100.
  /// Même arithmétique entière que le Java : `(200g + b) ~/ (2b)`.
  static int efficiency(int totalEarnings, int evOptimalEarnings) {
    if (evOptimalEarnings <= 0) return 0;
    final points =
        (200 * totalEarnings + evOptimalEarnings) ~/ (2 * evOptimalEarnings);
    return points > maxPoints ? maxPoints : points;
  }
}
