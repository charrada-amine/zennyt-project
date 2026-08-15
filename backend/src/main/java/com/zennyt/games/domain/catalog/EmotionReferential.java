package com.zennyt.games.domain.catalog;

import com.zennyt.games.domain.vo.EmotionDefinition;

import java.util.List;
import java.util.Optional;

/**
 * Port — référentiel des 45 émotions d'« Emotional Radar v2 » (Cowen &amp; Keltner
 * + littérature). Source unique de vérité côté serveur : le client n'envoie qu'une
 * {@code key} d'émotion, jamais un score ni une distance.
 *
 * <p>L'implémentation vivante {@code JsonEmotionReferential} charge la banque depuis
 * {@code resources/games/emotional_radar_emotions.json}. Le contenu (répartition,
 * coordonnées sémantiques) est <b>provisoire</b> tant que le psychologue n'a pas
 * fourni le référentiel définitif — même patron que « Je Décide ».
 */
public interface EmotionReferential {

    /** Toutes les émotions du référentiel, ordre stable. */
    List<EmotionDefinition> all();

    /** Une émotion par sa clé, ou {@code empty} si inconnue. */
    Optional<EmotionDefinition> byKey(String key);

    /** true si le référentiel est vide (gate de jouabilité). */
    default boolean isEmpty() {
        return all().isEmpty();
    }

    /** Nombre d'émotions chargées. */
    default int size() {
        return all().size();
    }
}
