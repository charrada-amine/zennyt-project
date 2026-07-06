package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Métriques de « Predictive Puzzle » (Planifik #3 — Tour de Hanoï).
 *
 * <p>Le client soumet des mesures de planification/exécution par niveau — jamais
 * un score. Le mini-jeu enchaîne plusieurs niveaux : les métriques portent la
 * liste {@link #levels()}. Le domaine ({@code PlanifikScoringService}) note
 * chaque niveau /10 (barème catégoriel de la fiche) puis agrège par moyenne
 * arrondie en un score unique de mini-jeu (un seul {@code Attempt}).
 *
 * @param levels métriques par niveau joué (au moins un niveau)
 */
public record PrevisionPuzzleMetrics(List<PrevisionPuzzleLevel> levels) implements GameMetrics {

    public PrevisionPuzzleMetrics {
        if (levels == null || levels.isEmpty()) {
            throw new IllegalArgumentException("levels ne doit pas être vide");
        }
        if (levels.stream().anyMatch(l -> l == null)) {
            throw new IllegalArgumentException("levels contient une valeur invalide");
        }
        levels = List.copyOf(levels);
    }

    public int levelCount() {
        return levels.size();
    }
}
