package com.zennyt.games.domain.vo;

/** Indicateurs descriptifs d'un niveau, pratique comprise. */
public record ObjectLocationLevelReport(
    ObjectLocationPhase phase,
    int levelIndex,
    int objectCount,
    boolean completed,
    boolean timedOut,
    boolean passed,
    int exactCount,
    int swapCount,
    int localErrorCount,
    int globalErrorCount,
    int unplacedCount,
    double exactAccuracyPercent,
    double averageDisplacementCells,
    int recallDurationMs,
    int actionCount,
    int repositionCount,
    Double averageFirstPlacementIntervalMs
) {
}
