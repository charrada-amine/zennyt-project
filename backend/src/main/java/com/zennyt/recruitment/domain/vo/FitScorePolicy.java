package com.zennyt.recruitment.domain.vo;

/** Seuils d'affichage du fit score. */
public final class FitScorePolicy {
    // PROVISOIRE — à valider avec le produit.
    public static final int GOOD_FIT_MIN_SCORE = 70;

    // CdC Fit Score v3 §3.3, mécanisme 2 — seuils de couverture des jeux
    // psychométriques (à valider avec les RH, cf. fit_score/16-prochaines-etapes.md).
    public static final int COVERAGE_THRESHOLD_WITH_HARD_SKILLS = 60;
    public static final int COVERAGE_THRESHOLD_SOFT_ONLY = 70;

    private FitScorePolicy() {}
}
