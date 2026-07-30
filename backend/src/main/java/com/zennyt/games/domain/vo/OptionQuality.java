package com.zennyt.games.domain.vo;

/**
 * Qualité d'une option de réponse « Je Décide », avec le score /3 associé.
 *
 * <p>Les libellés reprennent <b>mot pour mot</b> le vocabulaire de la fiche
 * « JE DÉCIDE ». L'échelle 0..3 est celle de la fiche ({@code item_score_scale=0..3}).
 *
 * <p><b>⚠️ Règle provisoire (couche isolée).</b> Étiqueter une option par sa
 * <i>qualité</i> plutôt que par un score par scénario est une <b>déduction
 * défendable</b> (voir {@code DecisionProvisionalRules}) : le psychologue n'aura
 * qu'à poser l'un de ces 4 mots sur chaque option — il ne réinvente aucun barème,
 * et le moteur ne change pas. Le catalogue déclare une {@code OptionQuality} par
 * option, jamais un score brut.
 */
public enum OptionQuality {
    /** optimal / cohérent → 3 pts. */
    OPTIMAL(3),
    /** satisfaisant / suboptimal → 2 pts. */
    SATISFACTORY(2),
    /** partiel / incohérent → 1 pt. */
    PARTIAL(1),
    /** déficitaire / non pertinent → 0 pt. */
    DEFICIENT(0);

    private final int points;

    OptionQuality(int points) {
        this.points = points;
    }

    /** Score /3 de l'échelle de la fiche (0..3). */
    public int points() {
        return points;
    }
}
