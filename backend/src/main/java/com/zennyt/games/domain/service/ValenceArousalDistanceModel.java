package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.EmotionDefinition;

/**
 * Implémentation <b>PROVISOIRE</b> du modèle de distance sémantique : distance
 * euclidienne dans le plan valence/arousal, normalisée dans [0,1].
 *
 * <p>Le plan couvre valence ∈ [-1,1] (étendue 2) et arousal ∈ [0,1] (étendue 1) ;
 * la distance maximale possible vaut donc √(2² + 1²) = √5, valeur par laquelle on
 * divise pour obtenir un résultat dans [0,1]. À remplacer par la distance dans
 * l'espace dimensionnel réel de Cowen &amp; Keltner (cf. EMOTIONAL_RADAR_V2_TASKS.md).
 */
public final class ValenceArousalDistanceModel implements SemanticDistanceModel {

    /** √(2² + 1²) — distance euclidienne maximale du plan valence/arousal. */
    private static final double MAX_DISTANCE = Math.sqrt(5.0);

    @Override
    public double distance(EmotionDefinition a, EmotionDefinition b) {
        if (a == null || b == null) {
            throw new IllegalArgumentException("deux émotions sont requises");
        }
        double dv = a.valence() - b.valence();
        double da = a.arousal() - b.arousal();
        return Math.sqrt(dv * dv + da * da) / MAX_DISTANCE;
    }
}
