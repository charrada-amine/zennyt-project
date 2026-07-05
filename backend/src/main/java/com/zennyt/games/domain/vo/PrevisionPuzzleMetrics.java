package com.zennyt.games.domain.vo;

/**
 * Metrics for Planifik mini-game #3: Predictive Puzzle.
 *
 * <p>The client submits measured planning/execution outcomes only; the score is
 * calculated by the domain service.
 */
public record PrevisionPuzzleMetrics(
    boolean targetCompleted,
    int sequenceErrors,
    int unnecessaryMoves,
    int retries,
    int plannedMoves,
    int optimalMoves
) implements GameMetrics {
    public PrevisionPuzzleMetrics {
        if (sequenceErrors < 0) throw new IllegalArgumentException("sequenceErrors >= 0 requis");
        if (unnecessaryMoves < 0) throw new IllegalArgumentException("unnecessaryMoves >= 0 requis");
        if (retries < 0) throw new IllegalArgumentException("retries >= 0 requis");
        if (plannedMoves < 0) throw new IllegalArgumentException("plannedMoves >= 0 requis");
        if (optimalMoves < 1) throw new IllegalArgumentException("optimalMoves >= 1 requis");
    }
}
