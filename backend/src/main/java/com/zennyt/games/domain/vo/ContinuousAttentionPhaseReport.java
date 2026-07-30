package com.zennyt.games.domain.vo;

/** Indicateurs descriptifs d'une phase TEST, sans interprétation clinique. */
public record ContinuousAttentionPhaseReport(
    ContinuousAttentionPhase phase,
    int targetCount,
    int nonTargetCount,
    int hitCount,
    int omissionCount,
    int commissionCount,
    int correctRejectionCount,
    double hitRatePercent,
    double omissionRatePercent,
    double falseAlarmRatePercent,
    double correctRejectionRatePercent,
    double balancedAccuracyPercent,
    Double averageHitReactionTimeMs,
    Double medianHitReactionTimeMs,
    Double stdDevHitReactionTimeMs,
    Double reactionTimeCoefficientOfVariation,
    double dPrime,
    double responseBiasC
) {
}
