package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ReflectivePauseConfig;

/**
 * Mesures brutes d'un moment de pression.
 */
public record ReflectivePauseMomentMetric(
    String momentId,
    ReflectivePauseResponseType selectedResponse,
    int responseTimeMs,
    boolean minimumTimerReached
) {
    public ReflectivePauseMomentMetric {
        if (momentId == null || momentId.isBlank()) {
            throw new IllegalArgumentException("momentId requis");
        }
        if (!ReflectivePauseConfig.momentIds().contains(momentId)) {
            throw new IllegalArgumentException(
                "Moment Reflective Pause inconnu : " + momentId);
        }
        if (selectedResponse == null) {
            throw new IllegalArgumentException("selectedResponse requis");
        }
        if (responseTimeMs < 0) {
            throw new IllegalArgumentException("responseTimeMs doit être >= 0");
        }
        boolean reachedFromTime =
            responseTimeMs >= ReflectivePauseConfig.MINIMUM_PAUSE_MS;
        if (minimumTimerReached != reachedFromTime) {
            throw new IllegalArgumentException(
                "minimumTimerReached incohérent avec responseTimeMs");
        }
    }

    public boolean nonImpulsive() {
        return ReflectivePauseConfig.isNonImpulsive(selectedResponse);
    }

    public boolean recommended() {
        return ReflectivePauseConfig.isRecommended(momentId, selectedResponse);
    }
}
