package com.zennyt.games.api.dto;

import com.zennyt.games.domain.model.Attempt;
import com.zennyt.games.domain.model.GameSession;
import com.zennyt.games.domain.vo.MoveFastFlexibilityReport;
import com.zennyt.games.domain.vo.PrevisionPuzzleReport;

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
    PrevisionPuzzleIndicatorsResponse previsionPuzzleIndicators
) {
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

    public static GameSessionResponse from(GameSession s) {
        return from(s, null, null);
    }

    public static GameSessionResponse from(GameSession s,
                                           MoveFastFlexibilityReport moveFastReport,
                                           PrevisionPuzzleReport previsionPuzzleReport) {
        return new GameSessionResponse(
            s.id(), s.playerId(), s.gameType().name(), s.status().name(),
            s.compositeRaw(), s.compositeMax(), s.normalizedScore(),
            s.attempts().stream().map(AttemptResponse::from).toList(),
            s.startedAt(), s.completedAt(),
            moveFastReport == null ? null : MoveFastIndicatorsResponse.from(moveFastReport),
            previsionPuzzleReport == null ? null
                : PrevisionPuzzleIndicatorsResponse.from(previsionPuzzleReport));
    }
}
