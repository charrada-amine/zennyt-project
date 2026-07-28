package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.Attempt;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.vo.DecisionReport;
import com.zennyt.games.domain.vo.EmotionalRadarReport;
import com.zennyt.games.domain.vo.MemoryQuestReport;
import com.zennyt.games.domain.vo.MoveFastFlexibilityReport;
import com.zennyt.games.domain.vo.PrevisionPuzzleReport;
import com.zennyt.games.domain.vo.ScoreBreakdown;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTO de réponse : état complet d'une session avec son score composite. */
public record GameSessionResponse(
    UUID id,
    UUID playerId,
    String gameType,
    String status,
    int compositeRaw,
    int compositeMax,
    double normalized,
    List<AttemptResponse> attempts,
    Instant startedAt,
    Instant completedAt,
    MoveFastIndicatorsResponse moveFastIndicators,
    PrevisionPuzzleIndicatorsResponse previsionPuzzleIndicators,
    MemoryQuestIndicatorsResponse memoryQuestIndicators,
    DecisionIndicatorsResponse decisionIndicators,
    EmotionalRadarIndicatorsResponse emotionalRadarIndicators,
    List<ScoreBreakdownLineResponse> scoreBreakdown
) {
    /**
     * Indicateurs de reconnaissance émotionnelle (calculés serveur).
     * Présent uniquement quand le résultat soumis concerne Emotional Radar.
     */
    public record EmotionalRadarIndicatorsResponse(
        int scenesPlayed,
        double emotionAccuracyPercent,
        double nuanceAccuracyPercent,
        double intensityCalibrationPercent,
        int averageResponseTimeMs,
        int helpOpenedCount,
        List<ConfusionResponse> confusedEmotions
    ) {
        /** Une confusion : famille attendue vs famille choisie. */
        public record ConfusionResponse(String expected, String selected) {
        }

        static EmotionalRadarIndicatorsResponse from(EmotionalRadarReport r) {
            return new EmotionalRadarIndicatorsResponse(
                r.scenesPlayed(),
                r.emotionAccuracyPercent(),
                r.nuanceAccuracyPercent(),
                r.intensityCalibrationPercent(),
                r.averageResponseTimeMs(),
                r.helpOpenedCount(),
                r.confusedEmotions().stream()
                    .map(c -> new ConfusionResponse(
                        c.expected().name(), c.selected().name()))
                    .toList());
        }
    }
    /** Résultat d'un mini-jeu au sein de la session. */
    public record AttemptResponse(String miniGame, ScoreResponse score, Instant recordedAt) {
        static AttemptResponse from(Attempt a) {
            return new AttemptResponse(
                a.miniGame().name(), ScoreResponse.from(a.score()), a.recordedAt());
        }
    }

    /**
     * Indicateurs de flexibilité cognitive « Je bouge » (calculés serveur).
     * Présent uniquement quand le résultat soumis concerne Move Fast.
     */
    public record MoveFastIndicatorsResponse(
        double precisionRatio,
        double averageReactionTimeMs,
        double medianReactionTimeMs,
        double stdDevReactionTimeMs,
        double fastResponsesPercent,
        double slowResponsesPercent,
        double switchResponseTimeAvgMs,
        double nonSwitchResponseTimeAvgMs,
        double switchCostMs,
        int perseverativeErrorsCount,
        int correctResponsesRuleOrientation,
        int correctResponsesRuleMovement,
        int sessionDurationSec,
        String sessionCompletionStatus,
        boolean calibrationApplied,
        boolean calibrationReliable,
        double calibrationOffsetMs,
        double averageReactionTimeAdjustedMs,
        double medianReactionTimeAdjustedMs,
        double fastResponsesPercentAdjusted,
        double slowResponsesPercentAdjusted,
        double switchCostAdjustedMs
    ) {
        static MoveFastIndicatorsResponse from(MoveFastFlexibilityReport r) {
            return new MoveFastIndicatorsResponse(
                r.precisionRatio(), r.averageReactionTimeMs(), r.medianReactionTimeMs(),
                r.stdDevReactionTimeMs(), r.fastResponsesPercent(), r.slowResponsesPercent(),
                r.switchResponseTimeAvgMs(), r.nonSwitchResponseTimeAvgMs(), r.switchCostMs(),
                r.perseverativeErrorsCount(), r.correctResponsesRuleOrientation(),
                r.correctResponsesRuleMovement(), r.sessionDurationSec(), r.sessionCompletionStatus(),
                r.calibrationApplied(), r.calibrationReliable(), r.calibrationOffsetMs(),
                r.averageReactionTimeAdjustedMs(), r.medianReactionTimeAdjustedMs(),
                r.fastResponsesPercentAdjusted(), r.slowResponsesPercentAdjusted(),
                r.switchCostAdjustedMs());
        }
    }

    /** Indicateurs qualitatifs « Predictive Puzzle » (calculés serveur, hors /10). */
    public record PrevisionPuzzleIndicatorsResponse(
        boolean globalPlanSuccess,
        int levelsPlayed,
        int levelsCompleted,
        List<LevelBreakdownResponse> levels
    ) {
        public record LevelBreakdownResponse(
            int levelIndex, int discCount, int score, boolean completed, boolean firstTrySuccess) {
        }

        static PrevisionPuzzleIndicatorsResponse from(PrevisionPuzzleReport r) {
            return new PrevisionPuzzleIndicatorsResponse(
                r.globalPlanSuccess(), r.levelsPlayed(), r.levelsCompleted(),
                r.levels().stream()
                    .map(l -> new LevelBreakdownResponse(
                        l.levelIndex(), l.discCount(), l.score(), l.completed(), l.firstTrySuccess()))
                    .toList());
        }
    }

    /** Indicateurs « J'investigue » (calculés serveur ; notes par tâche + composite). */
    public record MemoryQuestIndicatorsResponse(
        int compositeScore,
        int sameOrderScore,
        int reverseOrderScore,
        Integer restoreScore,
        Integer afterDistractionScore,
        int highestSequenceLength,
        boolean distractionQuestionCorrect,
        boolean missionBPlayed,
        boolean distractionPlayed,
        int finalLevel,
        boolean sessionValid,
        int timeoutTaskCount
    ) {
        static MemoryQuestIndicatorsResponse from(MemoryQuestReport r) {
            return new MemoryQuestIndicatorsResponse(
                r.compositeScore(), r.sameOrderScore(), r.reverseOrderScore(),
                r.restoreScore(), r.afterDistractionScore(), r.highestSequenceLength(),
                r.distractionQuestionCorrect(), r.missionBPlayed(), r.distractionPlayed(),
                r.finalLevel(), r.sessionValid(), r.timeoutTaskCount());
        }
    }

    /** Indicateurs « Je Décide » (calculés serveur ; détail par dimension + SCW + validité). */
    public record DecisionIndicatorsResponse(
        int rawScore,
        int rawMax,
        int scwScore,
        String level,
        List<DimensionScoreResponse> dimensions,
        List<String> interpretations,
        boolean avgTimePlausible,
        boolean randomResponseRateOk,
        boolean impulsiveRateOk,
        boolean deviceLatencyWithinNorm,
        boolean sessionUsable,
        double averageResponseTimeMs,
        double medianResponseTimeMs,
        double stdDevResponseTimeMs,
        double impulsiveResponsePercent,
        double slowResponsePercent,
        double intraSessionVariability,
        int decisionChangesCount,
        double averageResponseTimeAdjustedMs,
        boolean dtScoreCalibrationAdjusted,
        boolean calibrationApplied,
        boolean calibrationReliable,
        double calibrationOffsetMs
    ) {
        public record DimensionScoreResponse(
            String dimension, Integer score, int maxScore, boolean exploitable, int answeredItems) {
        }

        static DecisionIndicatorsResponse from(DecisionReport r) {
            return new DecisionIndicatorsResponse(
                r.rawScore(), r.rawMax(), r.scwScore(), r.level(),
                r.dimensions().stream()
                    .map(d -> new DimensionScoreResponse(
                        d.dimension().name(), d.score(), d.maxScore(), d.exploitable(), d.answeredItems()))
                    .toList(),
                r.interpretations(),
                r.avgTimePlausible(), r.randomResponseRateOk(), r.impulsiveRateOk(),
                r.deviceLatencyWithinNorm(), r.sessionUsable(),
                r.averageResponseTimeMs(), r.medianResponseTimeMs(), r.stdDevResponseTimeMs(),
                r.impulsiveResponsePercent(), r.slowResponsePercent(), r.intraSessionVariability(),
                r.decisionChangesCount(), r.averageResponseTimeAdjustedMs(),
                r.dtScoreCalibrationAdjusted(), r.calibrationApplied(), r.calibrationReliable(),
                r.calibrationOffsetMs());
        }
    }

    /** Une ligne du détail du score (panneau « d'où viennent mes points »). */
    public record ScoreBreakdownLineResponse(
        String kind, String label, String detail, Integer points, Integer maxPoints) {
        static ScoreBreakdownLineResponse from(ScoreBreakdown.Line l) {
            return new ScoreBreakdownLineResponse(
                l.kind().name(), l.label(), l.detail(), l.points(), l.maxPoints());
        }
    }

    public static GameSessionResponse from(GameSession s) {
        return from(s, null, null, null, null, null, null);
    }

    public static GameSessionResponse from(GameSession s,
                                           MoveFastFlexibilityReport moveFastReport,
                                           PrevisionPuzzleReport previsionPuzzleReport,
                                           MemoryQuestReport memoryQuestReport,
                                           DecisionReport decisionReport,
                                           EmotionalRadarReport emotionalRadarReport,
                                           ScoreBreakdown scoreBreakdown) {
        return new GameSessionResponse(
            s.id(), s.playerId(), s.gameType().name(), s.status().name(),
            s.compositeRaw(), s.compositeMax(), s.normalizedScore(),
            s.attempts().stream().map(AttemptResponse::from).toList(),
            s.startedAt(), s.completedAt(),
            moveFastReport == null ? null : MoveFastIndicatorsResponse.from(moveFastReport),
            previsionPuzzleReport == null ? null
                : PrevisionPuzzleIndicatorsResponse.from(previsionPuzzleReport),
            memoryQuestReport == null ? null
                : MemoryQuestIndicatorsResponse.from(memoryQuestReport),
            decisionReport == null ? null : DecisionIndicatorsResponse.from(decisionReport),
            emotionalRadarReport == null ? null
                : EmotionalRadarIndicatorsResponse.from(emotionalRadarReport),
            scoreBreakdown == null ? null
                : scoreBreakdown.lines().stream().map(ScoreBreakdownLineResponse::from).toList());
    }
}
