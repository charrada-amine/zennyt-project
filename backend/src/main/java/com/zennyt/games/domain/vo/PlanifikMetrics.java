package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Métriques brutes remontées par le mini-jeu « Chemin Optimal » (Planifik #1).
 *
 * <p>Ce sont des mesures objectives collectées côté client (voir fiche
 * « Je planifie ») — jamais un score. Le mini-jeu enchaîne plusieurs niveaux :
 * les métriques portent la liste {@link #levels()} (une entrée par niveau). Le
 * domaine ({@code PlanifikScoringService}) note chaque niveau /10 puis agrège
 * (moyenne arrondie) en un score unique de mini-jeu — ce qui préserve la
 * sémantique de l'agrégat (un seul {@code Attempt} par mini-jeu).
 *
 * @param levels métriques par niveau (au moins un niveau)
 */
public record PlanifikMetrics(List<OptimalPathLevel> levels) implements GameMetrics {

    public PlanifikMetrics {
        if (levels == null || levels.isEmpty()) {
            throw new IllegalArgumentException("levels ne doit pas être vide");
        }
        if (levels.stream().anyMatch(l -> l == null)) {
            throw new IllegalArgumentException("levels contient une valeur invalide");
        }
        levels = List.copyOf(levels);
    }

    /**
     * Fabrique de compatibilité mono-niveau : construit une métrique à un seul
     * niveau depuis les champs plats historiques. Le booléen d'évitement mappe
     * {@code TOTAL}/{@code NONE} et le compteur d'objectifs {@code YES}/{@code NO}.
     */
    public PlanifikMetrics(int attempts, int pathLength, int optimalLength,
                           boolean costlyZonesAvoided, int secondaryObjectives) {
        this(List.of(new OptimalPathLevel(
            0, attempts, pathLength, optimalLength,
            costlyZonesAvoided ? CostlyZonesAvoided.TOTAL : CostlyZonesAvoided.NONE,
            secondaryObjectives > 0 ? SecondaryObjectivesReached.YES : SecondaryObjectivesReached.NO)));
    }

    public int levelCount() {
        return levels.size();
    }
}
