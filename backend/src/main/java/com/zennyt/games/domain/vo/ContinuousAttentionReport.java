package com.zennyt.games.domain.vo;

import java.util.List;

/** Rapport serveur descriptif du protocole Long Rosvold X/AX. */
public record ContinuousAttentionReport(
    String protocolVersion,
    boolean completed,
    boolean sessionValid,
    boolean interrupted,
    int provisionalAccuracyScore,
    ContinuousAttentionPhaseReport xPhase,
    ContinuousAttentionPhaseReport axPhase,
    List<ContinuousAttentionEpochReport> epochs,
    int axTargetCount,
    int ayCount,
    int bxCount,
    int byCount,
    int extraResponseCount,
    int backgroundEventCount,
    int droppedFrameCount,
    int timingDeviationCount,
    List<String> validityIssues
) {
    public ContinuousAttentionReport {
        epochs = List.copyOf(epochs);
        validityIssues = List.copyOf(validityIssues);
    }
}
