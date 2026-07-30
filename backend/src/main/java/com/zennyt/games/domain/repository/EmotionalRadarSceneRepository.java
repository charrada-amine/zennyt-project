package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.SceneMediaType;

import java.util.Optional;
import java.util.UUID;

/**
 * Port d'écriture des scènes « Emotional Radar » (gestion de contenu).
 *
 * <p>Distinct du {@code EmotionalRadarSceneCatalog}, qui ne sert qu'à <b>lire</b>
 * des scènes jouables. Ce port existe parce qu'une scène média en cours de
 * préparation n'est pas encore représentable en {@link EmotionalRadarScene} : le VO
 * refuse une scène IMAGE/VIDEO sans fichier ni équivalent textuel. L'état
 * intermédiaire reste donc confiné à l'infrastructure, et le domaine n'exprime que
 * l'intention — « rattache ce média à cette scène ».
 */
public interface EmotionalRadarSceneRepository {

    /**
     * Type de média d'une scène, active ou non.
     *
     * <p>Permet au use case de choisir le type de ressource à téléverser sans
     * connaître l'entité de persistance.
     */
    Optional<SceneMediaType> mediaTypeOf(UUID sceneId);

    /**
     * Rattache un média à une scène et renvoie la scène désormais complète.
     *
     * <p>La scène ne redevient jouable que si son équivalent textuel est présent
     * (et sa transcription, pour une vidéo) — l'implémentation en est garante.
     *
     * @throws IllegalArgumentException si la scène reste incomplète après l'ajout
     */
    EmotionalRadarScene attachMedia(UUID sceneId, String url, String publicId,
                                    String altText, String transcript);
}
