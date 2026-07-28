package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.EmotionalRadarSceneRepository;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.SceneMediaType;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/** Implémente le port d'écriture des scènes ; isole l'état intermédiaire incomplet. */
@Component
public class EmotionalRadarSceneRepositoryAdapter implements EmotionalRadarSceneRepository {

    private final JpaEmotionalRadarSceneRepository jpa;

    public EmotionalRadarSceneRepositoryAdapter(JpaEmotionalRadarSceneRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Optional<SceneMediaType> mediaTypeOf(UUID sceneId) {
        return jpa.findById(sceneId).map(EmotionalRadarSceneEntity::getMediaType);
    }

    @Override
    public EmotionalRadarScene attachMedia(UUID sceneId, String url, String publicId,
                                           String altText, String transcript) {
        EmotionalRadarSceneEntity scene = jpa.findById(sceneId)
            .orElseThrow(() -> new IllegalArgumentException("Scène introuvable : " + sceneId));

        scene.attachMedia(url, publicId, altText, transcript);

        // toDomain() revalide les invariants d'accessibilité : une scène média
        // encore dépourvue d'équivalent textuel lève ici, plutôt que d'être servie
        // incomplète plus tard.
        return jpa.save(scene).toDomain();
    }
}
