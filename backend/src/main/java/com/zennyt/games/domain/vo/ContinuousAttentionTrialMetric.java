package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;

/**
 * Mesure brute et auto-validante d'un essai Long Rosvold.
 *
 * <p>La cohérence de séquence (lettre précédente, cible et timeline) est
 * contrôlée par {@link ContinuousAttentionMetrics}, qui dispose du contexte de
 * phase et de bloc.
 */
public record ContinuousAttentionTrialMetric(
    int trialIndex,
    String previousLetter,
    String currentLetter,
    int responseCode,
    int correct,
    Integer latencyMs,
    long scheduledOnsetMs,
    long actualOnsetMs,
    Long responseTimestampMs,
    int actualDisplayDurationMs,
    int actualIsiDurationMs,
    ContinuousAttentionInputSource inputSource,
    int extraResponseCount,
    boolean interrupted
) {
    public ContinuousAttentionTrialMetric {
        if (trialIndex < 1 || trialIndex > ContinuousAttentionConfig.TRIALS_PER_BLOCK) {
            throw new IllegalArgumentException("trialIndex doit être compris entre 1 et 31");
        }
        validateLetter(previousLetter, true, "previousLetter");
        validateLetter(currentLetter, false, "currentLetter");
        if (responseCode != ContinuousAttentionConfig.RESPONSE_CODE_NONE
            && responseCode != ContinuousAttentionConfig.RESPONSE_CODE_SPACE) {
            throw new IllegalArgumentException("responseCode doit valoir 0 ou 57");
        }
        if (correct != 0 && correct != 1) {
            throw new IllegalArgumentException("correct doit valoir 0 ou 1");
        }
        if (scheduledOnsetMs < 0 || actualOnsetMs < 0
            || actualDisplayDurationMs < 0 || actualIsiDurationMs < 0
            || extraResponseCount < 0) {
            throw new IllegalArgumentException("Les métriques temporelles doivent être positives");
        }

        if (responseCode == ContinuousAttentionConfig.RESPONSE_CODE_NONE) {
            if (latencyMs != null || responseTimestampMs != null || inputSource != null) {
                throw new IllegalArgumentException(
                    "Sans réponse, latencyMs, responseTimestampMs et inputSource doivent être null");
            }
        } else {
            if (latencyMs == null || responseTimestampMs == null || inputSource == null) {
                throw new IllegalArgumentException(
                    "Une réponse 57 exige latencyMs, responseTimestampMs et inputSource");
            }
            if (latencyMs < 0 || latencyMs >= ContinuousAttentionConfig.LETTER_DISPLAY_MS) {
                throw new IllegalArgumentException("latencyMs doit appartenir à [0, 690)");
            }
            if (responseTimestampMs < actualOnsetMs
                || responseTimestampMs - actualOnsetMs != latencyMs.longValue()) {
                throw new IllegalArgumentException(
                    "responseTimestampMs - actualOnsetMs doit être égal à latencyMs");
            }
        }
    }

    private static void validateLetter(String value, boolean nullable, String field) {
        if (value == null && nullable) {
            return;
        }
        if (value == null || value.length() != 1
            || value.charAt(0) < 'A' || value.charAt(0) > 'Z') {
            throw new IllegalArgumentException(field + " doit être une lettre A-Z");
        }
    }

    public boolean responded() {
        return responseCode == ContinuousAttentionConfig.RESPONSE_CODE_SPACE;
    }
}
