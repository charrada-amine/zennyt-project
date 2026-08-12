package com.zennyt.games.domain.service;

import com.zennyt.games.domain.vo.EmotionDefinition;

/**
 * Modèle de distance sémantique entre deux émotions — cœur de l'axe « finesse de
 * discrimination » d'« Emotional Radar v2 ». Faible distance = émotions proches =
 * scène difficile.
 *
 * <p>L'implémentation {@link ValenceArousalDistanceModel} est <b>PROVISOIRE</b>
 * (distance euclidienne dans un plan valence/arousal normalisé). Elle sera remplacée
 * par la distance dans l'espace réel de Cowen &amp; Keltner sans toucher au reste du
 * moteur : c'est l'intérêt de ce port.
 */
public interface SemanticDistanceModel {

    /** Distance normalisée dans [0,1] : 0 = identiques, 1 = maximalement éloignées. */
    double distance(EmotionDefinition a, EmotionDefinition b);
}
