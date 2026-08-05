package com.zennyt.games.domain.vo;

import java.util.List;
import java.util.Objects;

/** Rapport serveur descriptif de « Je place », sans norme ni diagnostic. */
public record ObjectLocationReport(
    String protocolVersion,
    ObjectLocationCompletionReason completionReason,
    boolean completed,
    boolean sessionValid,
    boolean technicalValid,
    boolean minimumLevelsValid,
    boolean progressionValid,
    boolean timingValid,
    int provisionalAccuracyScore,
    int completedLevelCount,
    int passedLevelCount,
    int administeredObjectCount,
    int exactPlacementCount,
    int swapCount,
    int localErrorCount,
    int globalErrorCount,
    int unplacedCount,
    double exactAccuracyPercent,
    double swapRatePercent,
    double localErrorRatePercent,
    double globalErrorRatePercent,
    double averageDisplacementCells,
    int span,
    Double loadSlope,
    Double averageFirstPlacementIntervalMs,
    int repositionCount,
    int backgroundEventCount,
    int focusLossCount,
    int orientationChangeCount,
    int droppedFrameCount,
    int timingDeviationCount,
    List<ObjectLocationLevelReport> levels,
    List<String> validityIssues
) {
    public ObjectLocationReport {
        levels = List.copyOf(Objects.requireNonNull(levels, "levels"));
        validityIssues = List.copyOf(Objects.requireNonNull(validityIssues, "validityIssues"));
    }
}
