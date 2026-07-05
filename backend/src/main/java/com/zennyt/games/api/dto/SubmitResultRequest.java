package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * DTO de requête : soumettre les métriques d'un mini-jeu.
 *
 * <p>Le client n'envoie que des métriques mesurées ; le score est calculé
 * serveur. {@link #toMetrics()} convertit vers le Value Object du domaine.
 */
public record SubmitResultRequest(
    @NotNull MiniGame miniGame,
    @NotNull @Valid Metrics metrics
) {
    /** Payload union. The [miniGame] value selects which fields are required. */
    public record Metrics(
        @Min(1) Integer attempts,
        @Min(0) Integer pathLength,
        @Min(1) Integer optimalLength,
        Boolean costlyZonesAvoided,
        @Min(0) Integer secondaryObjectives,
        @Size(min = 1) List<Boolean> correctResponses,
        List<@Min(0) Integer> reactionTimesMs,
        Boolean targetCompleted,
        @Min(0) Integer sequenceErrors,
        @Min(0) Integer unnecessaryMoves,
        @Min(0) Integer retries,
        @Min(0) Integer plannedMoves,
        @Min(1) Integer optimalMoves
    ) {}

    public GameMetrics toMetrics() {
        return switch (miniGame) {
            case OPTIMAL_PATH -> new PlanifikMetrics(
                required(metrics.attempts(), "attempts"),
                required(metrics.pathLength(), "pathLength"),
                required(metrics.optimalLength(), "optimalLength"),
                required(metrics.costlyZonesAvoided(), "costlyZonesAvoided"),
                required(metrics.secondaryObjectives(), "secondaryObjectives"));
            case MOVE_FAST_CORE -> new MoveFastMetrics(
                metrics.correctResponses(), metrics.reactionTimesMs());
            case PREVISION_PUZZLE -> new PrevisionPuzzleMetrics(
                required(metrics.targetCompleted(), "targetCompleted"),
                required(metrics.sequenceErrors(), "sequenceErrors"),
                required(metrics.unnecessaryMoves(), "unnecessaryMoves"),
                required(metrics.retries(), "retries"),
                required(metrics.plannedMoves(), "plannedMoves"),
                required(metrics.optimalMoves(), "optimalMoves"));
            case TASK_SCHEDULING -> throw new IllegalArgumentException(
                "Métriques non encore implémentées pour " + miniGame);
        };
    }

    private static <T> T required(T value, String field) {
        if (value == null) {
            throw new IllegalArgumentException("Champ métrique requis : " + field);
        }
        return value;
    }
}
