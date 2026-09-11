package com.zennyt.games.domain.vo;

/**
 * Famille de coping au sens de Carver.
 *
 * <p>Carver, Scheier &amp; Weintraub (1989), <i>Journal of Personality and Social
 * Psychology</i>, 56(2), 267-283, puis Carver (1997), <i>International Journal of
 * Behavioral Medicine</i>, 4, 92-100 : les échelles du COPE et du Brief COPE sont
 * <b>regroupées</b> en centrées problème, centrées émotion et dysfonctionnelles —
 * jamais ordonnées de la meilleure à la pire. Chez Lazarus &amp; Folkman (1984),
 * l'efficacité d'une stratégie dépend du contexte : il n'existe pas de
 * « meilleure » stratégie dans l'absolu.
 *
 * <p>C'est pourquoi le profil de coping accompagne le score plutôt que d'en
 * dériver : il décrit une conduite là où le score la classe.
 */
public enum CopingFamily {

    /** Agir sur la situation — active coping, planning. */
    PROBLEM_FOCUSED,

    /** Agir sur le vécu — positive reframing, humor, acceptance. */
    EMOTION_FOCUSED,

    /** Se soustraire ou ressasser — behavioral disengagement, venting, self-blame. */
    DYSFUNCTIONAL,

    /**
     * Correspondance non tranchée avec le Brief COPE.
     *
     * <p>Deux des huit stratégies du client n'ont pas d'équivalent univoque :
     * « Seek support » recouvre à la fois le soutien ÉMOTIONNEL (centré émotion)
     * et le soutien INSTRUMENTAL (centré problème), que Carver sépare en deux
     * échelles ; « Breathe / pause » relève plutôt de la modulation de la
     * réponse chez Gross (1998) que d'une échelle du COPE.
     *
     * <p>Les ranger d'office fausserait le profil. On les compte à part, et le
     * psychologue tranchera.
     */
    UNRESOLVED
}
