package com.zennyt.games.domain.catalog;

import com.zennyt.games.domain.vo.EmotionalRadarScene;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du catalogue de scènes d'« Emotional Radar » (même patron que
 * {@code DecisionScenarioCatalog}).
 *
 * <p>Le domaine ne connaît ni JPA ni la façon dont les scènes sont stockées : il
 * demande des scènes, l'infrastructure les fournit. Cela permet de remplacer la
 * source (base, fichier, service de contenu) sans toucher au moteur de notation.
 *
 * <p>⚠️ Les scènes renvoyées portent la clé de correction : ce port est réservé au
 * serveur et ne doit jamais alimenter directement une réponse HTTP.
 */
public interface EmotionalRadarSceneCatalog {

    /** Scènes actives, triées par {@code sceneOrder}. */
    List<EmotionalRadarScene> scenes();

    /** Published administration bank, with active-catalog fallback for old sessions. */
    default List<EmotionalRadarScene> scenes(UUID bankId) {
        return scenes();
    }

    /** Une scène par identifiant, si elle existe et est active. */
    Optional<EmotionalRadarScene> findById(UUID sceneId);

    /** Nombre de scènes réellement disponibles (peut être &lt; total_scenes visé). */
    default int size() {
        return scenes().size();
    }

    /**
     * Le mini-jeu est jouable dès qu'au moins une scène est rédigée.
     * Sert à piloter {@code MiniGame.EMOTIONAL_RADAR_CORE.isPlayable()} — même
     * logique que le catalogue « Je Décide », qui reste vide.
     */
    default boolean isPlayable() {
        return !scenes().isEmpty();
    }
}
