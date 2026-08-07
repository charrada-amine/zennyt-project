package com.zennyt.games.domain.vo;

import java.util.List;
import java.util.Objects;

/** Indicateurs serveur de « Je coordonne », descriptifs hors score global. */
public record CoordinationReport(
    String protocolVersion,
    CoordinationInputSource inputSource,
    boolean completed,
    boolean sessionValid,
    boolean interrupted,
    int provisionalAccuracyScore,
    double overallAccuracyPercent,
    double fastAccuracyPercent,
    double slowAccuracyPercent,
    double longSegmentAccuracyPercent,
    double shortSegmentAccuracyPercent,
    double averageCenterDistance,
    long testExecutionTimeMs,
    boolean accuracyValid,
    boolean executionTimeValid,
    boolean taskValid,
    boolean technicalValid,
    int sampleCount,
    int absentSampleCount,
    int backgroundEventCount,
    int droppedFrameCount,
    int timingDeviationCount,
    int samplingGapCount,
    List<String> validityIssues
) {
    public CoordinationReport {
        validityIssues = List.copyOf(Objects.requireNonNull(validityIssues, "validityIssues"));
    }
}
