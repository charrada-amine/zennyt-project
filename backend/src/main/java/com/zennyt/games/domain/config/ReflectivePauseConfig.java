package com.zennyt.games.domain.config;

import com.zennyt.games.domain.vo.ReflectivePauseResponseType;

import java.util.Map;
import java.util.Set;

/**
 * Règles « Reflective Pause » issues du developer handoff.
 *
 * <p>Le client envoie les mesures brutes ; cette configuration serveur décide
 * si une réponse est impulsive ou recommandée et porte les poids du barème
 * 3 + 4 + 3 = 10. Le mock Dart doit rester strictement identique.
 */
public final class ReflectivePauseConfig {

    private ReflectivePauseConfig() {
    }

    public static final int TOTAL_MOMENTS = 10;
    public static final int MINIMUM_PAUSE_MS = 3_000;
    public static final int CONTROLLED_REACTION_MAX = 3;
    public static final int NON_IMPULSIVE_MAX = 4;
    public static final int STEP_BACK_MAX = 3;
    public static final int TOTAL_MAX = 10;

    /**
     * Réponses recommandées du « Content map / pressure moments ».
     *
     * <p>Le moment 3 indique explicitement « Wait, then reformulate calmly » :
     * les deux choix sont donc acceptés comme prise de recul, sans inventer une
     * préférence entre eux.
     */
    private static final Map<String, Set<ReflectivePauseResponseType>> RECOMMENDED =
        Map.ofEntries(
            Map.entry("PRESSURE_01", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("PRESSURE_02", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("PRESSURE_03", Set.of(
                ReflectivePauseResponseType.WAIT,
                ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("PRESSURE_04", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("PRESSURE_05", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("PRESSURE_06", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("PRESSURE_07", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("PRESSURE_08", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("PRESSURE_09", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("PRESSURE_10", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)));

    public static Set<String> momentIds() {
        return RECOMMENDED.keySet();
    }

    public static boolean isRecommended(
            String momentId, ReflectivePauseResponseType response) {
        Set<ReflectivePauseResponseType> expected = RECOMMENDED.get(momentId);
        if (expected == null) {
            throw new IllegalArgumentException(
                "Moment Reflective Pause inconnu : " + momentId);
        }
        return expected.contains(response);
    }

    public static boolean isNonImpulsive(ReflectivePauseResponseType response) {
        return response != ReflectivePauseResponseType.RESPOND_IMPULSIVELY;
    }

    public static double criterionScore(int successes, int total, int maxPoints) {
        if (total <= 0) {
            return 0.0;
        }
        return roundOneDecimal(successes * maxPoints / (double) total);
    }

    public static int totalScore(double controlled, double nonImpulsive, double stepBack) {
        return (int) Math.round(controlled + nonImpulsive + stepBack);
    }

    public static String interpret(int score) {
        if (score <= 4) {
            return "Strong impulsivity";
        }
        if (score <= 7) {
            return "Good stress management";
        }
        return "Very good self-control";
    }

    public static double roundOneDecimal(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
