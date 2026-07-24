package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.AdministrationMode;
import com.zennyt.games.domain.vo.CostlyZonesAvoided;
import com.zennyt.games.domain.vo.DecisionItemResponse;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryTaskKind;
import com.zennyt.games.domain.vo.MemoryTaskResult;
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
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
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
        Boolean distractionQuestionCorrect,
        @Min(1) Integer finalLevel,
        Boolean sessionCompleted,
        @Valid List<MemoryTaskPayload> tasks,
        // « Ordonnancement de tâches » (TASK_SCHEDULING) — mesures brutes.
        Boolean dependenciesRespected,
        Boolean timeConstraintsRespected,
        @Min(0) Integer planningCoherence,
        @Min(0) Integer adjustmentCount,
        // « Je Décide » (DECISION_CORE) — mesures par item + contexte de session.
        @Size(min = 1) @Valid List<DecisionItemPayload> decisionItems,
        String sessionLanguage,
        String administrationMode,
        @Min(0) Integer age,
        String educationLevel,
        @Min(0) Integer fatigue,
        @Min(0) Integer motivation
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

    /**
     * Réponse mesurée à un item « Je Décide ». Le client envoie l'option choisie
     * et le temps — jamais de qualité ni de points (décidés serveur via le catalogue).
     */
    public record DecisionItemPayload(
        @NotNull String itemId,
        @NotNull com.zennyt.games.domain.vo.DecisionDimension dimension,
        String selectedOptionId,
        @NotNull @Min(0) Integer responseTimeMs,
        Boolean answered,
        @Min(0) Integer decisionChangesCount
    ) {}

    /** Une tâche « J'investigue » mesurée (le timeout est décidé serveur). */
    public record MemoryTaskPayload(
        @NotNull MemoryTaskKind kind,
        @NotNull @Min(0) Integer correct,
        @NotNull @Min(0) Integer total,
        @NotNull @Min(0) Integer responseTimeMs
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
                Boolean.TRUE.equals(metrics.distractionQuestionCorrect()),
                metrics.finalLevel() == null ? 1 : metrics.finalLevel(),
                metrics.sessionCompleted() == null || metrics.sessionCompleted(),
                metrics.tasks() == null ? List.of()
                    : metrics.tasks().stream().map(SubmitResultRequest::toMemoryTask).toList());
            case TASK_SCHEDULING -> new TaskSchedulingMetrics(
                required(metrics.dependenciesRespected(), "dependenciesRespected"),
                required(metrics.timeConstraintsRespected(), "timeConstraintsRespected"),
                required(metrics.planningCoherence(), "planningCoherence"),
                required(metrics.adjustmentCount(), "adjustmentCount"));
            case DECISION_CORE -> new DecisionMetrics(
                required(metrics.decisionItems(), "decisionItems").stream()
                    .map(SubmitResultRequest::toDecisionItem).toList(),
                metrics.sessionLanguage(),
                metrics.administrationMode() == null ? AdministrationMode.SUPERVISED
                    : parseEnum(AdministrationMode.class, metrics.administrationMode()),
                metrics.age(), metrics.educationLevel(), metrics.fatigue(), metrics.motivation());
        };
    }

    private static DecisionItemResponse toDecisionItem(DecisionItemPayload p) {
        boolean answered = p.answered() == null || p.answered();
        return new DecisionItemResponse(
            required(p.itemId(), "itemId"),
            required(p.dimension(), "dimension"),
            p.selectedOptionId(),
            required(p.responseTimeMs(), "responseTimeMs"),
            answered,
            orZero(p.decisionChangesCount()));
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

    private static MemoryTaskResult toMemoryTask(MemoryTaskPayload p) {
        return new MemoryTaskResult(
            required(p.kind(), "kind"),
            required(p.correct(), "correct"),
            required(p.total(), "total"),
            required(p.responseTimeMs(), "responseTimeMs"));
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
