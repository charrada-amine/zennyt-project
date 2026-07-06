import 'game_metrics.dart';

/// Degré d'évitement des zones coûteuses sur un niveau. Aligné sur l'enum
/// CostlyZonesAvoided du contrat games.openapi.yaml.
enum CostlyZonesAvoided {
  total('TOTAL'),
  partial('PARTIAL'),
  none('NONE');

  final String wire;
  const CostlyZonesAvoided(this.wire);
}

/// Atteinte des objectifs secondaires d'un niveau. Aligné sur l'enum
/// SecondaryObjectivesReached du contrat games.openapi.yaml.
enum SecondaryObjectivesReached {
  yes('YES'),
  partial('PARTIAL'),
  no('NO');

  final String wire;
  const SecondaryObjectivesReached(this.wire);
}

/// Métriques objectives d'UN niveau de « Chemin Optimal ».
class PlanifikLevelMetrics {
  const PlanifikLevelMetrics({
    required this.levelIndex,
    required this.attempts,
    required this.pathLength,
    required this.optimalLength,
    required this.costlyZonesAvoided,
    required this.secondaryObjectivesReached,
  });

  final int levelIndex;
  final int attempts;
  final int pathLength;
  final int optimalLength;
  final CostlyZonesAvoided costlyZonesAvoided;
  final SecondaryObjectivesReached secondaryObjectivesReached;

  Map<String, dynamic> toJson() => {
    'levelIndex': levelIndex,
    'attempts': attempts,
    'pathLength': pathLength,
    'optimalLength': optimalLength,
    'costlyZonesAvoided': costlyZonesAvoided.wire,
    'secondaryObjectivesReached': secondaryObjectivesReached.wire,
  };
}

/// Métriques objectives du mini-jeu « Chemin Optimal » (Value Object).
///
/// Le mini-jeu enchaîne plusieurs niveaux : les métriques portent la liste
/// [levels]. Le serveur note chaque niveau /10 puis agrège par moyenne arrondie
/// (un seul Attempt par mini-jeu). Aligné sur OptimalPathMetrics du contrat.
class PlanifikMetrics extends GameMetrics {
  const PlanifikMetrics({required this.levels});

  final List<PlanifikLevelMetrics> levels;

  // ── Getters d'agrégat pour l'UI de détail (lecture seule) ────────────────

  /// Longueur totale de chemin tracée, tous niveaux confondus.
  int get pathLength => levels.fold(0, (s, l) => s + l.pathLength);

  /// Longueur optimale totale, tous niveaux confondus.
  int get optimalLength => levels.fold(0, (s, l) => s + l.optimalLength);

  /// Nombre d'essais moyen (arrondi) sur l'ensemble des niveaux.
  int get attempts => levels.isEmpty
      ? 1
      : (levels.fold(0, (s, l) => s + l.attempts) / levels.length).round();

  /// Zones coûteuses évitées sur TOUS les niveaux (évitement total partout).
  bool get costlyZonesAvoided =>
      levels.every((l) => l.costlyZonesAvoided == CostlyZonesAvoided.total);

  /// Nombre de niveaux dont les objectifs secondaires sont pleinement atteints.
  int get secondaryObjectives => levels
      .where((l) => l.secondaryObjectivesReached == SecondaryObjectivesReached.yes)
      .length;

  @override
  Map<String, dynamic> toJson() => {
    'levels': levels.map((l) => l.toJson()).toList(),
  };
}
