package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.AdministrationMode;
import com.zennyt.games.domain.vo.CostlyZonesAvoided;
import com.zennyt.games.domain.vo.DecisionItemResponse;
import com.zennyt.games.domain.vo.DecisionMetrics;
import com.zennyt.games.domain.vo.EmotionalRadarMetrics;
import com.zennyt.games.domain.vo.EmotionalRadarSceneMetric;
import com.zennyt.games.domain.vo.GameMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMetrics;
import com.zennyt.games.domain.vo.MemoryQuestMode;
import com.zennyt.games.domain.vo.MemoryTaskKind;
import com.zennyt.games.domain.vo.MemoryTaskResult;
import com.zennyt.games.domain.vo.MoveFastMetrics;
import com.zennyt.games.domain.vo.MoveFastResponse;
import com.zennyt.games.domain.vo.MoveFastRule;
import com.zennyt.games.domain.config.PrevisionPuzzleConfig;
import com.zennyt.games.domain.vo.CalibrationMethod;
import com.zennyt.games.domain.vo.ContinuousAttentionBlockMetric;
import com.zennyt.games.domain.vo.ContinuousAttentionInputSource;
import com.zennyt.games.domain.vo.ContinuousAttentionMetrics;
import com.zennyt.games.domain.vo.ContinuousAttentionPhase;
import com.zennyt.games.domain.vo.ContinuousAttentionTrialMetric;
import com.zennyt.games.domain.vo.CoordinationInputSource;
import com.zennyt.games.domain.vo.CoordinationMetrics;
import com.zennyt.games.domain.vo.CoordinationPhase;
import com.zennyt.games.domain.vo.CoordinationPointerSample;
import com.zennyt.games.domain.vo.CoordinationSegmentMetric;
import com.zennyt.games.domain.vo.CoordinationSpeed;
import com.zennyt.games.domain.vo.DeviceCalibration;
import com.zennyt.games.domain.vo.DeviceCategory;
import com.zennyt.games.domain.vo.InputMode;
import com.zennyt.games.domain.vo.OptimalPathLevel;
import com.zennyt.games.domain.vo.ObjectLocationActionType;
import com.zennyt.games.domain.vo.ObjectLocationCompletionReason;
import com.zennyt.games.domain.vo.ObjectLocationLevelMetric;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.domain.vo.ObjectLocationPhase;
import com.zennyt.games.domain.vo.ObjectLocationPlacementAction;
import com.zennyt.games.domain.vo.PlanifikMetrics;
import com.zennyt.games.domain.vo.PrevisionPuzzleLevel;
import com.zennyt.games.domain.vo.PrevisionPuzzleMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMetrics;
import com.zennyt.games.domain.vo.ReflectivePauseMomentMetric;
import com.zennyt.games.domain.vo.ReflectivePauseResponseType;
import com.zennyt.games.domain.vo.SecondaryObjectivesReached;
import com.zennyt.games.domain.vo.TaskSchedulingMetrics;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
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
        /** DIGITS / IMAGES / FULL — absent = FULL (clients antérieurs à la scission). */
        String memoryQuestMode,
        @Min(0) Integer distractionChallengesPlayed,
        @Min(0) Integer distractionChallengesSolved,
        @Min(0) Integer distractionTimeouts,
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
        @Min(0) Integer motivation,
        // « Emotional Radar » — mesures COMPORTEMENTALES uniquement. Aucune réponse
        // ni point : le score vient des réponses notées serveur scène par scène.
        @Size(min = 1) @Valid List<EmotionalRadarScenePayload> emotionalRadarScenes,
        // « Reflective Pause » — 10 choix + timings bruts, aucun point.
        @Size(min = 10, max = 10) @Valid
        List<ReflectivePauseMomentPayload> reflectivePauseMoments,
        // « Je continue » — protocole Long Rosvold complet, mesures brutes.
        String protocolVersion,
        @Size(min = 44, max = 44) @Valid
        List<ContinuousAttentionBlockPayload> blocks,
        Boolean interrupted,
        @Min(0) Integer backgroundEventCount,
        @Min(0) Integer droppedFrameCount,
        // « Je coordonne » — modalité + 14 segments de positions fixed-point.
        CoordinationInputSource inputSource,
        @Size(min = 14, max = 14) @Valid
        List<CoordinationSegmentPayload> coordinationSegments,
        // « Je place » — actions brutes uniquement, layout reconstruit serveur.
        ObjectLocationCompletionReason completionReason,
        @Size(min = 1, max = 7) @Valid
        List<ObjectLocationLevelPayload> objectLocationLevels,
        @Min(0) Integer focusLossCount,
        @Min(0) Integer orientationChangeCount
    ) {}

    /** Timings et actions brutes d'un niveau « Je place ». */
    public record ObjectLocationLevelPayload(
        @NotNull ObjectLocationPhase phase,
        @NotNull @Min(0) @Max(6) Integer levelIndex,
        @NotNull @Min(2) @Max(8) Integer objectCount,
        @NotNull @Min(0) @Max(12_250) Integer actualEncodingDurationMs,
        @NotNull @Min(0) @Max(2_250) Integer actualRetentionDurationMs,
        @NotNull @Min(0) @Max(32_250) Integer actualRecallDurationMs,
        @NotNull Boolean timedOut,
        @NotNull Boolean completed,
        @NotNull @Size(max = 256) @Valid
        List<ObjectLocationPlacementActionPayload> actions
    ) {}

    /** Une pose, un déplacement ou un retour à la réserve. */
    public record ObjectLocationPlacementActionPayload(
        @NotNull @Min(1) @Max(256) Integer actionIndex,
        @NotNull ObjectLocationActionType actionType,
        @NotNull @Size(min = 1, max = 48) String objectId,
        @Min(0) @Max(15) Integer targetCellIndex,
        @NotNull @Min(0) Long timestampMs
    ) {}

    /** Un segment contigu du protocole visuomoteur. */
    public record CoordinationSegmentPayload(
        @NotNull CoordinationPhase phase,
        @NotNull @Min(1) @Max(14) Integer segmentIndex,
        @NotNull CoordinationSpeed speed,
        @NotNull @Min(1) Integer nominalDurationMs,
        @NotNull @Min(0) Long actualStartMs,
        @NotNull @Min(1) Long actualEndMs,
        @NotNull @Size(min = 2, max = 2000) @Valid
        List<CoordinationPointerSamplePayload> samples
    ) {}

    /** Position pointeur brute ; aucune position de balle ni distance client. */
    public record CoordinationPointerSamplePayload(
        @NotNull @Min(1) @Max(2000) Integer sampleIndex,
        @NotNull @Min(0) Long timestampMs,
        @NotNull Boolean pointerPresent,
        @Min(0) @Max(1_000_000) Integer pointerX,
        @Min(0) @Max(1_000_000) Integer pointerY
    ) {}

    /** Un bloc de 31 essais du protocole Long Rosvold. */
    public record ContinuousAttentionBlockPayload(
        @NotNull ContinuousAttentionPhase phase,
        @NotNull @Min(1) Integer blockIndex,
        @NotNull @Size(min = 31, max = 31) @Valid
        List<ContinuousAttentionTrialPayload> trials
    ) {}

    /** Mesures temporelles et réponse brute d'un essai. */
    public record ContinuousAttentionTrialPayload(
        @NotNull @Min(1) @Max(31) Integer trialIndex,
        String previousLetter,
        @NotNull String currentLetter,
        @NotNull Integer responseCode,
        @NotNull Integer correct,
        @Min(0) @Max(689) Integer latencyMs,
        @NotNull @Min(0) Long scheduledOnsetMs,
        @NotNull @Min(0) Long actualOnsetMs,
        @Min(0) Long responseTimestampMs,
        @NotNull @Min(0) Integer actualDisplayDurationMs,
        @NotNull @Min(0) Integer actualIsiDurationMs,
        ContinuousAttentionInputSource inputSource,
        @NotNull @Min(0) Integer extraResponseCount,
        @NotNull Boolean interrupted
    ) {}

    /**
     * Mesures d'une scène « Emotional Radar ».
     *
     * <p>Volontairement dépourvu de {@code selectedEmotion}/{@code selectedNuance} :
     * ces choix ont déjà été envoyés — et notés — à la validation de la scène. Les
     * réintroduire ici rouvrirait la porte à un score falsifiable.
     */
    public record EmotionalRadarScenePayload(
        @NotNull UUID sceneId,
        @NotNull @Min(0) Integer responseTimeMs,
        Boolean helpOpened,
        Boolean fullscreenOpened,
        Boolean reducedMotion
    ) {}

    /** Mesures brutes d'un moment « Reflective Pause ». */
    public record ReflectivePauseMomentPayload(
        @NotNull String momentId,
        @NotNull ReflectivePauseResponseType selectedResponse,
        @NotNull @Min(0) Integer responseTimeMs,
        @NotNull Boolean minimumTimerReached
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
        @NotNull @Min(0) Integer responseTimeMs,
        /** Niveau d'origine — fixe le délai d'une tâche parasite. Absent = 1. */
        @Min(1) Integer level
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
            case MEMORY_QUEST_CORE -> toMemoryQuestMetrics(metrics);
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
            case EMOTIONAL_RADAR_CORE -> new EmotionalRadarMetrics(
                required(metrics.emotionalRadarScenes(), "emotionalRadarScenes").stream()
                    .map(SubmitResultRequest::toEmotionalRadarScene).toList());
            case REFLECTIVE_PAUSE_CORE -> new ReflectivePauseMetrics(
                required(metrics.reflectivePauseMoments(), "reflectivePauseMoments").stream()
                    .map(SubmitResultRequest::toReflectivePauseMoment).toList());
            case CONTINUOUS_ATTENTION_CORE -> new ContinuousAttentionMetrics(
                required(metrics.protocolVersion(), "protocolVersion"),
                required(metrics.blocks(), "blocks").stream()
                    .map(SubmitResultRequest::toContinuousAttentionBlock).toList(),
                required(metrics.sessionCompleted(), "sessionCompleted"),
                required(metrics.interrupted(), "interrupted"),
                required(metrics.backgroundEventCount(), "backgroundEventCount"),
                required(metrics.droppedFrameCount(), "droppedFrameCount"));
            case COORDINATION_TRACKING_CORE -> new CoordinationMetrics(
                required(metrics.protocolVersion(), "protocolVersion"),
                required(metrics.inputSource(), "inputSource"),
                required(metrics.coordinationSegments(), "coordinationSegments").stream()
                    .map(SubmitResultRequest::toCoordinationSegment).toList(),
                required(metrics.sessionCompleted(), "sessionCompleted"),
                required(metrics.interrupted(), "interrupted"),
                required(metrics.backgroundEventCount(), "backgroundEventCount"),
                required(metrics.droppedFrameCount(), "droppedFrameCount"));
            case OBJECT_LOCATION_BINDING_CORE -> new ObjectLocationMetrics(
                required(metrics.protocolVersion(), "protocolVersion"),
                required(metrics.completionReason(), "completionReason"),
                required(metrics.objectLocationLevels(), "objectLocationLevels").stream()
                    .map(SubmitResultRequest::toObjectLocationLevel).toList(),
                required(metrics.sessionCompleted(), "sessionCompleted"),
                required(metrics.interrupted(), "interrupted"),
                required(metrics.backgroundEventCount(), "backgroundEventCount"),
                required(metrics.focusLossCount(), "focusLossCount"),
                required(metrics.orientationChangeCount(), "orientationChangeCount"),
                required(metrics.droppedFrameCount(), "droppedFrameCount"));
        };
    }

    private static ObjectLocationLevelMetric toObjectLocationLevel(
            ObjectLocationLevelPayload payload) {
        return new ObjectLocationLevelMetric(
            required(payload.phase(), "phase"),
            required(payload.levelIndex(), "levelIndex"),
            required(payload.objectCount(), "objectCount"),
            required(payload.actualEncodingDurationMs(), "actualEncodingDurationMs"),
            required(payload.actualRetentionDurationMs(), "actualRetentionDurationMs"),
            required(payload.actualRecallDurationMs(), "actualRecallDurationMs"),
            required(payload.timedOut(), "timedOut"),
            required(payload.completed(), "completed"),
            required(payload.actions(), "actions").stream()
                .map(SubmitResultRequest::toObjectLocationAction).toList());
    }

    private static ObjectLocationPlacementAction toObjectLocationAction(
            ObjectLocationPlacementActionPayload payload) {
        return new ObjectLocationPlacementAction(
            required(payload.actionIndex(), "actionIndex"),
            required(payload.actionType(), "actionType"),
            required(payload.objectId(), "objectId"),
            payload.targetCellIndex(),
            required(payload.timestampMs(), "timestampMs"));
    }

    private static CoordinationSegmentMetric toCoordinationSegment(
            CoordinationSegmentPayload payload) {
        return new CoordinationSegmentMetric(
            required(payload.phase(), "phase"),
            required(payload.segmentIndex(), "segmentIndex"),
            required(payload.speed(), "speed"),
            required(payload.nominalDurationMs(), "nominalDurationMs"),
            required(payload.actualStartMs(), "actualStartMs"),
            required(payload.actualEndMs(), "actualEndMs"),
            required(payload.samples(), "samples").stream()
                .map(SubmitResultRequest::toCoordinationSample).toList());
    }

    private static CoordinationPointerSample toCoordinationSample(
            CoordinationPointerSamplePayload payload) {
        return new CoordinationPointerSample(
            required(payload.sampleIndex(), "sampleIndex"),
            required(payload.timestampMs(), "timestampMs"),
            required(payload.pointerPresent(), "pointerPresent"),
            payload.pointerX(), payload.pointerY());
    }

    private static ContinuousAttentionBlockMetric toContinuousAttentionBlock(
            ContinuousAttentionBlockPayload payload) {
        return new ContinuousAttentionBlockMetric(
            required(payload.phase(), "phase"),
            required(payload.blockIndex(), "blockIndex"),
            required(payload.trials(), "trials").stream()
                .map(SubmitResultRequest::toContinuousAttentionTrial)
                .toList());
    }

    private static ContinuousAttentionTrialMetric toContinuousAttentionTrial(
            ContinuousAttentionTrialPayload payload) {
        return new ContinuousAttentionTrialMetric(
            required(payload.trialIndex(), "trialIndex"),
            payload.previousLetter(),
            required(payload.currentLetter(), "currentLetter"),
            required(payload.responseCode(), "responseCode"),
            required(payload.correct(), "correct"),
            payload.latencyMs(),
            required(payload.scheduledOnsetMs(), "scheduledOnsetMs"),
            required(payload.actualOnsetMs(), "actualOnsetMs"),
            payload.responseTimestampMs(),
            required(payload.actualDisplayDurationMs(), "actualDisplayDurationMs"),
            required(payload.actualIsiDurationMs(), "actualIsiDurationMs"),
            payload.inputSource(),
            required(payload.extraResponseCount(), "extraResponseCount"),
            required(payload.interrupted(), "interrupted"));
    }

    private static ReflectivePauseMomentMetric toReflectivePauseMoment(
            ReflectivePauseMomentPayload payload) {
        return new ReflectivePauseMomentMetric(
            required(payload.momentId(), "momentId"),
            required(payload.selectedResponse(), "selectedResponse"),
            required(payload.responseTimeMs(), "responseTimeMs"),
            required(payload.minimumTimerReached(), "minimumTimerReached"));
    }

    private static EmotionalRadarSceneMetric toEmotionalRadarScene(EmotionalRadarScenePayload p) {
        return new EmotionalRadarSceneMetric(
            required(p.sceneId(), "sceneId"),
            required(p.responseTimeMs(), "responseTimeMs"),
            Boolean.TRUE.equals(p.helpOpened()),
            Boolean.TRUE.equals(p.fullscreenOpened()),
            Boolean.TRUE.equals(p.reducedMotion()));
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
            required(p.responseTimeMs(), "responseTimeMs"),
            p.level() == null ? 1 : p.level());
    }

    /**
     * Mesures de « J'investigue » — <b>ce qui est exigé dépend du MODE</b>.
     *
     * <p>Une partie d'IMAGES n'observe aucun chiffre : réclamer
     * {@code observedDigits} sans condition la rejetait à la soumission, si bien
     * que le jeu des images ne pouvait pas être noté du tout.
     */
    private static MemoryQuestMetrics toMemoryQuestMetrics(Metrics metrics) {
        MemoryQuestMode mode = metrics.memoryQuestMode() == null
            ? MemoryQuestMode.FULL
            : parseEnum(MemoryQuestMode.class, metrics.memoryQuestMode());
        boolean digits = mode.playsDigits();
        return new MemoryQuestMetrics(
            mode,
            digits ? required(metrics.observedDigits(), "observedDigits") : 0,
            digits ? required(metrics.correctSameDigits(), "correctSameDigits") : 0,
            digits ? required(metrics.correctReverseDigits(), "correctReverseDigits") : 0,
            digits ? required(metrics.highestSequenceLength(), "highestSequenceLength") : 0,
            digits ? orZero(metrics.objectCount()) : required(metrics.objectCount(), "objectCount"),
            orZero(metrics.restoreCorrect()),
            orZero(metrics.manipulationCount()),
            Boolean.TRUE.equals(metrics.distractionPlayed()),
            orZero(metrics.afterDistractionObserved()),
            orZero(metrics.afterDistractionCorrect()),
            Boolean.TRUE.equals(metrics.distractionQuestionCorrect()),
            orZero(metrics.distractionChallengesPlayed()),
            orZero(metrics.distractionChallengesSolved()),
            orZero(metrics.distractionTimeouts()),
            metrics.finalLevel() == null ? 1 : metrics.finalLevel(),
            metrics.sessionCompleted() == null || metrics.sessionCompleted(),
            metrics.tasks() == null ? List.of()
                : metrics.tasks().stream().map(SubmitResultRequest::toMemoryTask).toList());
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
