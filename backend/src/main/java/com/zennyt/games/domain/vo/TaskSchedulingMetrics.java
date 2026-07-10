package com.zennyt.games.domain.vo;

/**
 * Métriques brutes du mini-jeu « Ordonnancement de tâches » (Planifik #2).
 *
 * <p>Ce sont des mesures objectives collectées côté client (fiche « JE PLANIFIE —
 * Mini-jeu 2 ») — jamais un score. Le calcul déterministe est du ressort du
 * domaine ({@code PlanifikScoringService}), garantissant que le client ne peut
 * pas s'auto-attribuer de points.
 *
 * @param dependenciesRespected      toutes les dépendances entre tâches respectées (tout-ou-rien)
 * @param timeConstraintsRespected   toutes les contraintes horaires respectées (tout-ou-rien)
 * @param planningCoherence          cohérence du planning : 0 désordonné · 1 partiel · 2 clair
 * @param adjustmentCount            nombre BRUT de réajustements (le score dérivé est calculé serveur)
 */
public record TaskSchedulingMetrics(
    boolean dependenciesRespected,
    boolean timeConstraintsRespected,
    int planningCoherence,
    int adjustmentCount
) implements GameMetrics {
    public TaskSchedulingMetrics {
        if (planningCoherence < 0 || planningCoherence > 2) {
            throw new IllegalArgumentException("planningCoherence doit être dans [0, 2]");
        }
        if (adjustmentCount < 0) {
            throw new IllegalArgumentException("adjustmentCount doit être >= 0");
        }
    }
}
