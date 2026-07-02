package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * DTO de requête : soumettre les métriques d'un mini-jeu.
 *
 * <p>Le client n'envoie que des métriques mesurées ; le score est calculé
 * serveur. {@link #toMetrics()} convertit vers le Value Object du domaine.
 */
public record SubmitResultRequest(
    @NotNull MiniGame miniGame,
    @NotNull @Valid OptimalPathMetrics metrics
) {
    /** Métriques du mini-jeu « Chemin Optimal ». */
    public record OptimalPathMetrics(
        @Min(1) int attempts,
        @Min(0) int pathLength,
        @Min(1) int optimalLength,
        boolean costlyZonesAvoided,
        @Min(0) int secondaryObjectives
    ) {}

    public PlanifikMetrics toMetrics() {
        return new PlanifikMetrics(
            metrics.attempts(), metrics.pathLength(), metrics.optimalLength(),
            metrics.costlyZonesAvoided(), metrics.secondaryObjectives());
    }
}
