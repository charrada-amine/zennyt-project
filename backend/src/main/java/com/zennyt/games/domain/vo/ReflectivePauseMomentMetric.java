package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ReflectivePauseConfig;

/**
 * Mesures brutes d'un moment de pression.
 *
 * <p>Le support ({@code medium}) accompagne le choix et le délai, comme le
 * demande le client : lire un message et regarder une scène ne sollicitent pas
 * la même charge, et comparer deux délais suppose de savoir lequel des deux le
 * joueur a eu. Il reste facultatif — une session enregistrée avant l'intégration
 * de la banque n'en porte pas, et {@code null} se lit « non renseigné » plutôt
 * qu'un support par défaut qui fausserait la comparaison.
 */
public record ReflectivePauseMomentMetric(
    String momentId,
    ReflectivePauseResponseType selectedResponse,
    int responseTimeMs,
    boolean minimumTimerReached,
    ReflectivePauseMedium medium
) {
    /** Sans support précisé — une session antérieure à la banque client. */
    public ReflectivePauseMomentMetric(
            String momentId,
            ReflectivePauseResponseType selectedResponse,
            int responseTimeMs,
            boolean minimumTimerReached) {
        this(momentId, selectedResponse, responseTimeMs, minimumTimerReached, null);
    }

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
