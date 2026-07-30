package com.zennyt.games.domain.vo;

/**
 * Famille d'émotion de base — étape 1 d'« Emotional Radar ».
 *
 * <p>Les six familles sont figées par la maquette (grille 2×3 de l'écran de
 * gameplay) : elles ne dépendent pas du catalogue de scènes et ne sont donc pas
 * une donnée provisoire. Ce sont les <b>nuances</b> rattachées à chaque famille
 * qui, elles, sont partiellement provisoires
 * (voir {@code EmotionalRadarProvisionalRules}).
 */
public enum BasicEmotion {
    JOY,
    SADNESS,
    ANGER,
    FEAR,
    DISGUST,
    SURPRISE
}
