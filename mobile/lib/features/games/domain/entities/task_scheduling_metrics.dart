import 'game_metrics.dart';

/// Métriques objectives du mini-jeu « Ordonnancement de tâches » (Planifik #2).
///
/// Ce sont des mesures collectées pendant le jeu — jamais un score. Le serveur
/// (ou le mock) applique le barème /10. Aligné sur TaskSchedulingMetrics du
/// contrat games.openapi.yaml.
class TaskSchedulingMetrics extends GameMetrics {
  const TaskSchedulingMetrics({
    required this.dependenciesRespected,
    required this.timeConstraintsRespected,
    required this.planningCoherence,
    required this.adjustmentCount,
  });

  /// Toutes les dépendances respectées (tout-ou-rien).
  final bool dependenciesRespected;

  /// Toutes les contraintes horaires respectées (tout-ou-rien).
  final bool timeConstraintsRespected;

  /// Cohérence du planning : 0 désordonné · 1 partiel · 2 clair.
  final int planningCoherence;

  /// Nombre BRUT de réajustements (le score dérivé est calculé serveur).
  final int adjustmentCount;

  @override
  Map<String, dynamic> toJson() => {
    'dependenciesRespected': dependenciesRespected,
    'timeConstraintsRespected': timeConstraintsRespected,
    'planningCoherence': planningCoherence,
    'adjustmentCount': adjustmentCount,
  };
}
