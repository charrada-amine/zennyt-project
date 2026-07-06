package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.MoveFastConfig;

import java.util.List;

/**
 * Raw metrics for the cognitive flexibility game « Je bouge / Move Fast ».
 *
 * <p>Le client envoie une liste ordonnée de réponses mesurées ({@link MoveFastResponse}),
 * essais d'échauffement compris (marqués {@code practiceTrial}). Le serveur :
 * <ol>
 *   <li>exclut les essais d'échauffement du scoring et des statistiques ;</li>
 *   <li>rejoue la séquence correct/incorrect pour appliquer le barème en escalade
 *       (voir {@link MoveFastConfig}) ;</li>
 *   <li>dérive les indicateurs de flexibilité cognitive
 *       ({@link MoveFastFlexibilityReport}).</li>
 * </ol>
 *
 * <p>Anti-triche léger (fiche « Configuration ») : on rejette une soumission dont
 * le nombre d'essais notés dépasse {@code maxResponses}, ou dont la somme des
 * temps de réaction dépasse largement la durée de session prévue.
 *
 * @param practiceTrialExcludedCount nombre d'essais d'échauffement exclus (documente l'exclusion)
 * @param responses                  essais mesurés dans l'ordre de jeu (échauffement inclus)
 */
public record MoveFastMetrics(
    int practiceTrialExcludedCount,
    List<MoveFastResponse> responses
) implements GameMetrics {

    public MoveFastMetrics {
        if (practiceTrialExcludedCount < 0) {
            throw new IllegalArgumentException("practiceTrialExcludedCount doit être >= 0");
        }
        if (responses == null || responses.isEmpty()) {
            throw new IllegalArgumentException("responses ne doit pas être vide");
        }
        if (responses.stream().anyMatch(r -> r == null)) {
            throw new IllegalArgumentException("responses contient une valeur invalide");
        }
        responses = List.copyOf(responses);

        long flagged = responses.stream().filter(MoveFastResponse::practiceTrial).count();
        if (flagged != practiceTrialExcludedCount) {
            throw new IllegalArgumentException(
                "practiceTrialExcludedCount (" + practiceTrialExcludedCount
                    + ") incohérent avec le nombre d'essais d'échauffement marqués (" + flagged + ")");
        }

        long scored = responses.size() - flagged;
        if (scored == 0) {
            throw new IllegalArgumentException("aucune réponse notée (hors échauffement)");
        }

        // Anti-triche léger — condition de fin de session effective.
        MoveFastConfig.SessionEndCondition end = MoveFastConfig.SESSION_END_CONDITION;
        if (scored > end.maxResponses()) {
            throw new IllegalArgumentException(
                "Trop de réponses notées : " + scored + " > maxResponses=" + end.maxResponses());
        }
        long totalReactionMs = responses.stream().mapToLong(MoveFastResponse::reactionTimeMs).sum();
        if (totalReactionMs > (long) end.sessionSeconds() * 1000L) {
            throw new IllegalArgumentException(
                "Somme des temps de réaction implausible : " + totalReactionMs
                    + " ms > durée de session " + end.sessionSeconds() + " s");
        }
    }

    /** Essais réellement notés : échauffement exclu. */
    public List<MoveFastResponse> scoredResponses() {
        return responses.stream().filter(r -> !r.practiceTrial()).toList();
    }

    /** Séquence correct/incorrect des essais notés (pour rejouer le barème). */
    public List<Boolean> correctResponses() {
        return scoredResponses().stream().map(MoveFastResponse::correct).toList();
    }

    /** Temps de réaction des essais notés, alignés avec {@link #correctResponses()}. */
    public List<Integer> reactionTimesMs() {
        return scoredResponses().stream().map(MoveFastResponse::reactionTimeMs).toList();
    }

    public int responseCount() {
        return scoredResponses().size();
    }

    public long correctCount() {
        return scoredResponses().stream().filter(MoveFastResponse::correct).count();
    }

    public double accuracy() {
        return correctCount() * 100.0 / responseCount();
    }
}
