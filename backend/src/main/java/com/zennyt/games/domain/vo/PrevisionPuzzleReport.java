package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.PrevisionPuzzleConfig;

import java.util.List;

/**
 * Indicateurs qualitatifs de « Predictive Puzzle » (fiche Planifik #3).
 *
 * <p><b>Calculés côté serveur.</b> {@code globalPlanSuccess} (succès/échec du
 * plan) est un indicateur qualitatif qui reste <b>HORS du score /10</b> : il est
 * exposé dans la réponse mais n'entre pas dans le barème.
 */
public record PrevisionPuzzleReport(
    boolean globalPlanSuccess,
    int levelsPlayed,
    int levelsCompleted,
    List<LevelBreakdown> levels
) {
    /** Détail par niveau : score /10 et issue (hors barème global). */
    public record LevelBreakdown(
        int levelIndex,
        int discCount,
        int score,
        boolean completed,
        boolean firstTrySuccess
    ) {
    }

    /** Dérive les indicateurs depuis les métriques mesurées. */
    public static PrevisionPuzzleReport from(PrevisionPuzzleMetrics metrics) {
        List<LevelBreakdown> breakdowns = metrics.levels().stream()
            .map(l -> new LevelBreakdown(
                l.levelIndex(), l.discCount(),
                PrevisionPuzzleConfig.levelScore(
                    l.firstTrySuccess(), l.sequenceErrors(), l.plannedMoves(), l.optimalMoves()),
                l.completed(), l.firstTrySuccess()))
            .toList();

        int completed = (int) metrics.levels().stream()
            .filter(PrevisionPuzzleLevel::completed).count();
        boolean globalPlanSuccess = completed == metrics.levelCount();

        return new PrevisionPuzzleReport(
            globalPlanSuccess, metrics.levelCount(), completed, breakdowns);
    }
}
