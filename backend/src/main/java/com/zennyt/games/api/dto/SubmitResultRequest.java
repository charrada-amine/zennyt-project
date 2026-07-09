package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.CostlyZonesAvoided;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import com.zennyt.games.domain.config.PrevisionPuzzleConfig;
import com.zennyt.games.domain.vo.CalibrationMethod;
import com.zennyt.games.domain.vo.DeviceCalibration;
import com.zennyt.games.domain.vo.DeviceCategory;
import com.zennyt.games.domain.vo.InputMode;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.SecondaryObjectivesReached;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/**
 * DTO de requête : soumettre les métriques d'un mini-jeu.
 *
 * <p>Le client n'envoie que des métriques mesurées ; le score est calculé
 * serveur. {@link #toMetrics()} convertit vers le Value Object du domaine.
 */
public record SubmitResultRequest(
    @NotNull MiniGame miniGame,
    @NotNull @Valid Metrics metrics,
    @Valid DeviceCalibrationPayload deviceCalibration
) {
    /** Payload union. The [miniGame] value selects which fields are required. */
    public record Metrics(
        @Min(1) Integer attempts,
        @Min(0) Integer pathLength,
        @Min(1) Integer optimalLength,
        Boolean costlyZonesAvoided,
        @Min(0) Integer secondaryObjectives,
        @Valid List<OptimalPathLevelPayload> levels,
        @Min(0) Integer practiceTrialExcludedCount,
        @Size(min = 1) @Valid List<MoveFastResponsePayload> responses,
        @Size(min = 1) @Valid List<PrevisionPuzzleLevelPayload> previsionPuzzleLevels,
        // « J'investigue » (MEMORY_QUEST) — mesures par tâche.
        @Min(0) Integer observedDigits,
        @Min(0) Integer correctSameDigits,
        @Min(0) Integer correctReverseDigits,
        @Min(0) Integer highestSequenceLength,
        @Min(0) Integer objectCount,
        @Min(0) Integer restoreCorrect,
        @Min(0) Integer manipulationCount,
        Boolean distractionPlayed,
        @Min(0) Integer afterDistractionObserved,
        @Min(0) Integer afterDistractionCorrect,
        Boolean distractionQuestionCorrect
    ) {}

    /** Socle de calibrage appareil (optionnel). Le score n'en dépend pas pour Move Fast. */
    public record DeviceCalibrationPayload(
        @NotNull String calibrationMethod,
        @NotNull String inputMode,
        @NotNull String deviceCategory,
        @NotNull @Positive Double refreshRateHz,
        @Min(1) Integer hardwareConcurrency,
        @Positive Double deviceMemoryGb,
        @Min(0) Double inputProcessingLatencyMs
    ) {}

    /**
     * Convertit le calibrage en VO domaine ; {@code sessionId} vient du chemin
     * (jamais du client). Retourne {@code null} si aucun calibrage n'est fourni.
     */
    public DeviceCalibration toCalibration(UUID sessionId) {
        if (deviceCalibration == null) {
            return null;
        }
        DeviceCalibrationPayload c = deviceCalibration;
        return new DeviceCalibration(
            sessionId,
            parseEnum(CalibrationMethod.class, required(c.calibrationMethod(), "calibrationMethod")),
            parseEnum(InputMode.class, required(c.inputMode(), "inputMode")),
            parseEnum(DeviceCategory.class, required(c.deviceCategory(), "deviceCategory")),
            required(c.refreshRateHz(), "refreshRateHz"),
            c.hardwareConcurrency(),
            c.deviceMemoryGb(),
            c.inputProcessingLatencyMs());
    }

    private static <E extends Enum<E>> E parseEnum(Class<E> type, String value) {
        try {
            return Enum.valueOf(type, value.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException(
                "Valeur invalide pour " + type.getSimpleName() + " : " + value);
        }
    }

    /** Métriques d'un niveau « Predictive Puzzle » (score calculé serveur). */
    public record PrevisionPuzzleLevelPayload(
        @Min(0) Integer levelIndex,
        @NotNull @Min(1) Integer discCount,
        @NotNull Boolean firstTrySuccess,
        @NotNull @Min(0) Integer sequenceErrors,
        @NotNull @Min(0) Integer plannedMoves,
        @Min(1) Integer optimalMoves,
        @NotNull @Min(0) Integer retries,
        @NotNull Boolean completed
    ) {}

    /** Métriques d'un niveau « Chemin Optimal » (score calculé serveur). */
    public record OptimalPathLevelPayload(
        @Min(0) Integer levelIndex,
        @NotNull @Min(1) Integer attempts,
        @NotNull @Min(0) Integer pathLength,
        @NotNull @Min(1) Integer optimalLength,
        @NotNull CostlyZonesAvoided costlyZonesAvoided,
        @NotNull SecondaryObjectivesReached secondaryObjectivesReached
    ) {}

    /**
     * Un essai « Je bouge » mesuré (échauffement inclus). Le score et les
     * indicateurs de flexibilité sont calculés serveur — jamais par le client.
     */
    public record MoveFastResponsePayload(
        Boolean practiceTrial,
        @NotNull Boolean correct,
        @NotNull @Min(0) Integer reactionTimeMs,
        @NotNull MoveFastRule ruleActive,
        Boolean isSwitchTrial,
        Boolean appliedOldRule
    ) {}

    public GameMetrics toMetrics() {
        return switch (miniGame) {
            case OPTIMAL_PATH -> metrics.levels() != null && !metrics.levels().isEmpty()
                ? new PlanifikMetrics(metrics.levels().stream()
                    .map(SubmitResultRequest::toLevel).toList())
                : new PlanifikMetrics(
                    required(metrics.attempts(), "attempts"),
                    required(metrics.pathLength(), "pathLength"),
                    required(metrics.optimalLength(), "optimalLength"),
                    required(metrics.costlyZonesAvoided(), "costlyZonesAvoided"),
                    required(metrics.secondaryObjectives(), "secondaryObjectives"));
            case MOVE_FAST_CORE -> new MoveFastMetrics(
                required(metrics.practiceTrialExcludedCount(), "practiceTrialExcludedCount"),
                required(metrics.responses(), "responses").stream()
                    .map(SubmitResultRequest::toResponse).toList());
            case PREVISION_PUZZLE -> new PrevisionPuzzleMetrics(
                required(metrics.previsionPuzzleLevels(), "previsionPuzzleLevels").stream()
                    .map(SubmitResultRequest::toPuzzleLevel).toList());
            case MEMORY_QUEST_CORE -> new MemoryQuestMetrics(
                required(metrics.observedDigits(), "observedDigits"),
                required(metrics.correctSameDigits(), "correctSameDigits"),
                required(metrics.correctReverseDigits(), "correctReverseDigits"),
                required(metrics.highestSequenceLength(), "highestSequenceLength"),
                orZero(metrics.objectCount()),
                orZero(metrics.restoreCorrect()),
                orZero(metrics.manipulationCount()),
                Boolean.TRUE.equals(metrics.distractionPlayed()),
                orZero(metrics.afterDistractionObserved()),
                orZero(metrics.afterDistractionCorrect()),
                Boolean.TRUE.equals(metrics.distractionQuestionCorrect()));
            case TASK_SCHEDULING -> throw new IllegalArgumentException(
                "Métriques non encore implémentées pour " + miniGame);
        };
    }

    private static int orZero(Integer value) {
        return value == null ? 0 : value;
    }

    private static OptimalPathLevel toLevel(OptimalPathLevelPayload p) {
        return new OptimalPathLevel(
            p.levelIndex() == null ? 0 : p.levelIndex(),
            required(p.attempts(), "attempts"),
            required(p.pathLength(), "pathLength"),
            required(p.optimalLength(), "optimalLength"),
            required(p.costlyZonesAvoided(), "costlyZonesAvoided"),
            required(p.secondaryObjectivesReached(), "secondaryObjectivesReached"));
    }

    private static PrevisionPuzzleLevel toPuzzleLevel(PrevisionPuzzleLevelPayload p) {
        int discCount = required(p.discCount(), "discCount");
        // Optimal déterministe : recalculé serveur si absent (2^discCount − 1).
        int optimal = p.optimalMoves() == null
            ? PrevisionPuzzleConfig.optimalMoves(discCount)
            : p.optimalMoves();
        return new PrevisionPuzzleLevel(
            p.levelIndex() == null ? 0 : p.levelIndex(),
            discCount,
            required(p.firstTrySuccess(), "firstTrySuccess"),
            required(p.sequenceErrors(), "sequenceErrors"),
            required(p.plannedMoves(), "plannedMoves"),
            optimal,
            required(p.retries(), "retries"),
            required(p.completed(), "completed"));
    }

    private static MoveFastResponse toResponse(MoveFastResponsePayload p) {
        return new MoveFastResponse(
            Boolean.TRUE.equals(p.practiceTrial()),
            required(p.correct(), "correct"),
            required(p.reactionTimeMs(), "reactionTimeMs"),
            required(p.ruleActive(), "ruleActive"),
            Boolean.TRUE.equals(p.isSwitchTrial()),
            Boolean.TRUE.equals(p.appliedOldRule()));
    }

    private static <T> T required(T value, String field) {
        if (value == null) {
            throw new IllegalArgumentException("Champ métrique requis : " + field);
        }
        return value;
    }
}
