package com.zennyt.games.domain.vo;

/**
 * Grande famille d'une émotion du référentiel « Emotional Radar v2 »
 * (Cowen &amp; Keltner + littérature).
 *
 * <p>La répartition cible de la banque (brief 2026-08-12) est 18 / 20 / 3 / 4 sur
 * les 45 émotions. Sert notamment à garantir, lors de la sélection des distracteurs,
 * qu'on ne mélange pas des familles trop hétérogènes quand ce n'est pas voulu.
 */
public enum EmotionCategory {
    /** Émotions positives (joie, fierté, gratitude…). */
    POSITIVE,
    /** Émotions négatives (colère, honte, anxiété…). */
    NEGATIVE,
    /** Émotions prosociales (sympathie, compassion, gratitude…). */
    PROSOCIAL,
    /** Émotions ambivalentes ou cognitives (surprise, nostalgie, doute…). */
    AMBIVALENT_COGNITIVE
}
