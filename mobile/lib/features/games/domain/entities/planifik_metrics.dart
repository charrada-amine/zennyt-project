/// Métriques objectives du mini-jeu « Chemin Optimal » (Value Object).
///
/// Ce sont des mesures collectées pendant le jeu — jamais un score. Elles sont
/// envoyées au serveur qui calcule le score. Aligné sur OptimalPathMetrics du
/// contrat games.openapi.yaml.
class PlanifikMetrics {
  const PlanifikMetrics({
    required this.attempts,
    required this.pathLength,
    required this.optimalLength,
    required this.costlyZonesAvoided,
    required this.secondaryObjectives,
  });

  final int attempts;
  final int pathLength;
  final int optimalLength;
  final bool costlyZonesAvoided;
  final int secondaryObjectives;

  Map<String, dynamic> toJson() => {
    'attempts': attempts,
    'pathLength': pathLength,
    'optimalLength': optimalLength,
    'costlyZonesAvoided': costlyZonesAvoided,
    'secondaryObjectives': secondaryObjectives,
  };
}
