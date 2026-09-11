import 'game_metrics.dart';

/// Métriques objectives du « Planning journalier » (Planifik #2).
///
/// Mesures collectées pendant la partie — jamais un score. Le serveur (ou le
/// mock hors ligne) applique le barème /10. Aligné sur `TaskSchedulingMetrics`
/// du contrat `games.openapi.yaml`.
///
/// Des compteurs, et non des booléens : les trois premières composantes du
/// barème client se calculent sur des RATIOS. L'ancien contrat tout-ou-rien
/// donnait le même zéro à qui tenait huit contraintes sur neuf et à qui n'en
/// tenait aucune.
class TaskSchedulingMetrics extends GameMetrics {
  const TaskSchedulingMetrics({
    required this.universeId,
    required this.dependencyEdgeCount,
    required this.dependencyEdgesRespected,
    required this.directDependencyViolations,
    required this.timingConstraintCount,
    required this.timingConstraintsRespected,
    required this.collisionFree,
    required this.deadTimeRatio,
    required this.proactiveAdjustments,
    required this.reactiveAdjustments,
    this.levelsPlayed = 1,
    this.planningLatencyMs,
  });

  /// Univers tiré, pour la traçabilité d'une passation à l'autre.
  final String universeId;

  final int dependencyEdgeCount;
  final int dependencyEdgesRespected;

  /// Tâches lancées sans que leur prérequis soit terminé.
  ///
  /// Pénalisées à part : le référentiel y voit une erreur de règle, pas un
  /// simple sous-optimum d'ordre.
  final int directDependencyViolations;

  /// n RÉEL de contraintes horaires de l'univers — 5 à 7 selon l'univers.
  final int timingConstraintCount;
  final int timingConstraintsRespected;

  /// Aucun bloc horaire fixe empêché de démarrer à son heure.
  final bool collisionFree;

  /// Part de temps mort sur l'amplitude du planning, dans [0,1].
  final double deadTimeRatio;

  /// Corrections décidées avant tout signal d'erreur.
  final int proactiveAdjustments;

  /// Corrections déclenchées après un signal d'erreur.
  final int reactiveAdjustments;

  /// Nombre de plannings joués dans la partie.
  ///
  /// Les seuils d'autorégulation du référentiel — 1 puis 3 corrections — ont
  /// été calibrés sur UN planning. Une partie en enchaîne plusieurs, et les
  /// compteurs ci-dessus en font la somme : sans ce nombre, le serveur
  /// appliquerait un barème de manche à un total de partie, et toute partie où
  /// le joueur se reprend une fois par manche tomberait à zéro.
  final int levelsPlayed;

  /// Temps de réflexion avant le premier placement.
  ///
  /// Métrique DIAGNOSTIQUE : le référentiel la veut au profil qualitatif et
  /// explicitement hors du score — elle distingue un profil impulsif d'un
  /// profil délibératif à score égal. `null` si aucune tâche n'a été placée.
  final int? planningLatencyMs;

  int get adjustmentCount => proactiveAdjustments + reactiveAdjustments;

  @override
  Map<String, dynamic> toJson() => {
    'universeId': universeId,
    'dependencyEdgeCount': dependencyEdgeCount,
    'dependencyEdgesRespected': dependencyEdgesRespected,
    'directDependencyViolations': directDependencyViolations,
    'timingConstraintCount': timingConstraintCount,
    'timingConstraintsRespected': timingConstraintsRespected,
    'collisionFree': collisionFree,
    'deadTimeRatio': deadTimeRatio,
    'proactiveAdjustments': proactiveAdjustments,
    'reactiveAdjustments': reactiveAdjustments,
    'levelsPlayed': levelsPlayed,
    if (planningLatencyMs != null) 'planningLatencyMs': planningLatencyMs,
  };
}
