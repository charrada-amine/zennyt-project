package com.zennyt.recruitment.domain.vo;

import java.util.List;

/**
 * Sens d'évolution des résultats techniques d'un candidat sur un métier.
 *
 * <p><b>Pourquoi ce calcul est fait ici et pas par le modèle.</b> Le générateur recevait la
 * liste des tests avec la consigne « du plus récent au plus ancien » et devait en déduire la
 * direction. Il s'est trompé — deux fois, sur deux appels indépendants — et a annoncé une
 * progression à un candidat en baisse. Un résumé qui inverse la trajectoire est pire
 * qu'aucun résumé : il oriente une décision de recrutement dans le mauvais sens.
 *
 * <p>Déduire un ordre depuis une liste est exactement ce qu'un modèle de langue fait mal et
 * qu'une comparaison d'entiers fait de façon sûre. La direction est donc établie ici, puis
 * <b>énoncée</b> au modèle comme un fait qu'il doit reformuler sans le contredire.
 */
public enum HardSkillTrend {

    /** Un seul test noté : il n'y a pas de trajectoire à raconter. */
    SINGLE,
    /** Le dernier résultat dépasse le précédent d'au moins {@link #SEUIL_POINTS} points. */
    IMPROVING,
    /** L'écart entre les deux derniers reste dans le bruit. */
    STABLE,
    /** Le dernier résultat est inférieur au précédent d'au moins {@link #SEUIL_POINTS} points. */
    DECLINING;

    /**
     * En deçà de cet écart, parler de progression ou de recul serait interpréter du bruit :
     * deux QCM différents, conçus par deux recruteurs, ne sont pas comparables au point près.
     */
    public static final int SEUIL_POINTS = 10;

    /**
     * @param historique du plus récent au plus ancien — même ordre que
     *                   {@code TestResultRepository.findHardSkillHistory}. La comparaison
     *                   porte sur les deux premiers : c'est l'évolution récente qui intéresse
     *                   le lecteur, pas la moyenne de la carrière.
     */
    public static HardSkillTrend of(List<HardSkillHistoryEntry> historique) {
        if (historique == null || historique.size() < 2) return SINGLE;
        int ecart = historique.get(0).percentage() - historique.get(1).percentage();
        if (ecart >= SEUIL_POINTS) return IMPROVING;
        if (ecart <= -SEUIL_POINTS) return DECLINING;
        return STABLE;
    }

    /**
     * Énoncé factuel destiné au prompt — le modèle le reformule, il ne le recalcule pas.
     *
     * <p>Prend les deux pourcentages plutôt que l'historique : l'énoncé n'a pas à connaître
     * le type de la liste, et l'appelant en manipule déjà une projection différente.
     *
     * @param dernier   pourcentage du test le plus récent
     * @param precedent pourcentage du test qui le précède — ignoré si {@link #SINGLE}
     */
    public String asStatement(int dernier, int precedent) {
        if (this == SINGLE) {
            return "TRAJECTORY: only one test has been taken — there is no trend to comment "
                + "on. Do not describe any progression or decline.";
        }
        String direction = switch (this) {
            case IMPROVING -> "IMPROVING — the candidate's results are getting better";
            case DECLINING -> "DECLINING — the candidate's results are getting worse";
            default -> "STABLE — no meaningful change between the two most recent tests";
        };
        return "TRAJECTORY (established fact — state it as given, never recompute or "
            + "contradict it): " + direction + ". Most recent test: " + dernier
            + "%. The test before it: " + precedent + "%.";
    }
}
