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
     * Réaction la mieux cotée de chaque situation de la banque client.
     *
     * <p>Engendrée depuis {@code reflective_pause_bank.json} (TR-001 à TR-060)
     * par {@code tooling/games/convert-reflective-pause-bank.py} : la banque
     * cote chaque réponse de 0 à 3, et la « recommandée » est celle qui porte la
     * cotation maximale de sa fiche. Neuf situations laissent deux réponses à
     * égalité — elles sont toutes deux acceptées, plutôt que d'inventer une
     * préférence que le psychologue n'a pas tranchée.
     *
     * <p>Remplace la table écrite à la main sur dix moments inventés
     * (PRESSURE_01 à PRESSURE_10) : ces identifiants n'existent plus, et
     * {@link #isRecommended} lève sur un identifiant inconnu — une partie jouée
     * sur la vraie banque aurait échoué à l'enregistrement.
     */
    private static final Map<String, Set<ReflectivePauseResponseType>> RECOMMENDED =
        Map.ofEntries(
            Map.entry("TR-001", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-002", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-003", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-004", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-005", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-006", Set.of(
                ReflectivePauseResponseType.WAIT,
                ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-007", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-008", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-009", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-010", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-011", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-012", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-013", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-014", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-015", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-016", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-017", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-018", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-019", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-020", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-021", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-022", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-023", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-024", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-025", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-026", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-027", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-028", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-029", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-030", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-031", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-032", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-033", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-034", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-035", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-036", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-037", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-038", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-039", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-040", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-041", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-042", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-043", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-044", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-045", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-046", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-047", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-048", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-049", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-050", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-051", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-052", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-053", Set.of(ReflectivePauseResponseType.WAIT)),
            Map.entry("TR-054", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-055", Set.of(ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)),
            Map.entry("TR-056", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-057", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-058", Set.of(ReflectivePauseResponseType.BREATHE_ANALYZE)),
            Map.entry("TR-059", Set.of(ReflectivePauseResponseType.REFORMULATE_CALMLY)),
            Map.entry("TR-060", Set.of(
                ReflectivePauseResponseType.BREATHE_ANALYZE,
                ReflectivePauseResponseType.ASK_FOR_MORE_INFORMATION)));

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
