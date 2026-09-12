package com.zennyt.games.domain.vo;

/**
 * Métriques brutes du mini-jeu « Planning journalier » (Planifik #2).
 *
 * <p>Mesures objectives collectées côté client — jamais un score. Le calcul
 * déterministe appartient au domaine ({@code PlanifikScoringService}), de sorte
 * que le client ne puisse pas s'auto-attribuer de points.
 *
 * <p>Les trois premières composantes du barème client se calculent sur des
 * RATIOS, d'où des compteurs plutôt que des booléens : un joueur qui respecte
 * huit contraintes horaires sur neuf ne vaut pas celui qui n'en respecte
 * aucune, et l'ancien contrat tout-ou-rien les confondait.
 *
 * @param universeId                identifiant de l'univers tiré, pour la traçabilité
 * @param dependencyEdgeCount       nombre total d'arêtes de dépendance de l'univers
 * @param dependencyEdgesRespected  arêtes effectivement respectées
 * @param directDependencyViolations tâches lancées sans que leur prérequis soit terminé
 * @param timingConstraintCount     n RÉEL de contraintes horaires de l'univers (5 à 7)
 * @param timingConstraintsRespected contraintes horaires tenues
 * @param collisionFree             aucun bloc horaire fixe empêché de démarrer à l'heure
 * @param deadTimeRatio             part de temps mort sur l'amplitude du planning [0,1]
 * @param proactiveAdjustments      corrections décidées avant tout signal d'erreur
 * @param reactiveAdjustments       corrections déclenchées par une erreur signalée
 * @param levelsPlayed              nombre de plannings joués — les seuils
 *                                  d'autorégulation valent PAR planning
 * @param planningLatencyMs         temps de réflexion avant le premier placement —
 *                                  métrique DIAGNOSTIQUE, explicitement hors du score
 */
public record TaskSchedulingMetrics(
    String universeId,
    int dependencyEdgeCount,
    int dependencyEdgesRespected,
    int directDependencyViolations,
    int timingConstraintCount,
    int timingConstraintsRespected,
    boolean collisionFree,
    double deadTimeRatio,
    int proactiveAdjustments,
    int reactiveAdjustments,
    int levelsPlayed,
    Integer planningLatencyMs
) implements GameMetrics {

    public TaskSchedulingMetrics {
        // Un client antérieur aux manches multiples n'envoie rien : on retombe
        // sur un planning, c'est-à-dire exactement l'ancien barème.
        if (levelsPlayed <= 0) {
            levelsPlayed = 1;
        }
        if (dependencyEdgeCount < 0 || dependencyEdgesRespected < 0
            || dependencyEdgesRespected > dependencyEdgeCount) {
            throw new IllegalArgumentException(
                "arêtes de dépendance incohérentes : "
                    + dependencyEdgesRespected + "/" + dependencyEdgeCount);
        }
        if (directDependencyViolations < 0) {
            throw new IllegalArgumentException("directDependencyViolations doit être >= 0");
        }
        if (timingConstraintCount < 0 || timingConstraintsRespected < 0
            || timingConstraintsRespected > timingConstraintCount) {
            throw new IllegalArgumentException(
                "contraintes horaires incohérentes : "
                    + timingConstraintsRespected + "/" + timingConstraintCount);
        }
        if (deadTimeRatio < 0.0 || deadTimeRatio > 1.0) {
            throw new IllegalArgumentException("deadTimeRatio hors [0,1] : " + deadTimeRatio);
        }
        if (proactiveAdjustments < 0 || reactiveAdjustments < 0) {
            throw new IllegalArgumentException("compteurs de corrections négatifs");
        }
        if (planningLatencyMs != null && planningLatencyMs < 0) {
            throw new IllegalArgumentException("planningLatencyMs doit être >= 0");
        }
    }

    /** Total des corrections, toutes natures confondues. */
    public int adjustmentCount() {
        return proactiveAdjustments + reactiveAdjustments;
    }
}
