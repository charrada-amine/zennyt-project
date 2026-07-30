package com.zennyt.games.domain.vo;

/**
 * Mode de passation « Je Décide » (fiche « JE DÉCIDE »).
 *
 * <p>En mode {@link #UNSUPERVISED}, les contrôles de qualité de session
 * (plausibilité des temps, réponses aléatoires) sont <b>renforcés</b>.
 */
public enum AdministrationMode {
    /** Passation supervisée (examinateur présent). */
    SUPERVISED,
    /** Passation autonome — contrôles de plausibilité renforcés. */
    UNSUPERVISED
}
