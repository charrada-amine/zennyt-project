package com.zennyt.games.domain.vo;

/**
 * Un essai mesuré de « Je bouge / Move Fast ».
 *
 * <p>Le client envoie une réponse par essai (essais d'échauffement compris,
 * marqués {@code practiceTrial}). Le serveur exclut les essais d'échauffement du
 * scoring et de toutes les statistiques, puis dérive les indicateurs de
 * flexibilité cognitive ({@link MoveFastFlexibilityReport}) — le client ne
 * calcule jamais ces indicateurs.
 *
 * @param practiceTrial  true si essai d'échauffement (exclu du scoring et des stats)
 * @param correct        true si la réponse était correcte
 * @param reactionTimeMs temps de réaction mesuré, en millisecondes
 * @param ruleActive     règle en vigueur sur cet essai
 * @param isSwitchTrial  true si la règle a changé par rapport à l'essai précédent
 * @param appliedOldRule true si l'erreur correspond à l'application de l'ancienne règle
 *                       (erreur persévérative — marqueur clé de rigidité cognitive)
 */
public record MoveFastResponse(
    boolean practiceTrial,
    boolean correct,
    int reactionTimeMs,
    MoveFastRule ruleActive,
    boolean isSwitchTrial,
    boolean appliedOldRule
) {
    public MoveFastResponse {
        if (reactionTimeMs < 0) {
            throw new IllegalArgumentException("reactionTimeMs doit être >= 0");
        }
        if (ruleActive == null) {
            throw new IllegalArgumentException("ruleActive est requis");
        }
        if (appliedOldRule && correct) {
            throw new IllegalArgumentException(
                "appliedOldRule (erreur persévérative) est incohérent avec correct=true");
        }
    }
}
