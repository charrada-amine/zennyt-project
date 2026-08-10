package com.zennyt.games.domain.vo;

/** Agrégat descriptif d'une époque de cinq blocs de test. */
public record ContinuousAttentionEpochReport(
    ContinuousAttentionPhase phase,
    int epochIndex,
    double hitRatePercent,
    double falseAlarmRatePercent,
    Double averageHitReactionTimeMs,
    Double reactionTimeVariabilityMs,
    double dPrime
) {
}
