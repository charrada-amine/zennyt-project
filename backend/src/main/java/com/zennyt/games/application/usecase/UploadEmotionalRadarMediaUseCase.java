package com.zennyt.games.application.usecase;

import com.zennyt.games.application.port.GamesMediaStoragePort;
import com.zennyt.games.domain.repository.EmotionalRadarSceneRepository;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.domain.vo.SceneMediaType;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Use case : téléverser le média (image ou vidéo) d'une scène et le rattacher.
 *
 * <p>Une scène média reste <b>inactive</b> tant qu'elle n'a ni fichier ni équivalent
 * textuel : elle ne peut donc pas être servie incomplète, ce qui satisfait la
 * planche « Accessibility Compliance » par construction plutôt que par convention.
 *
 * <p>Ne dépend que de ports du domaine — jamais de l'infrastructure (AGENTS.md §7.2,
 * vérifié par ArchUnit).
 */
@Service
public class UploadEmotionalRadarMediaUseCase {

    private final EmotionalRadarSceneRepository scenes;
    private final GamesMediaStoragePort storage;

    public UploadEmotionalRadarMediaUseCase(EmotionalRadarSceneRepository scenes,
                                            GamesMediaStoragePort storage) {
        this.scenes = scenes;
        this.storage = storage;
    }

    @Transactional
    public EmotionalRadarScene execute(UUID sceneId, byte[] content, String filename,
                                       String altText, String transcript) {

        SceneMediaType type = scenes.mediaTypeOf(sceneId)
            .orElseThrow(() -> new NotFoundException("Scène introuvable : " + sceneId));

        if (!type.requiresMedia()) {
            throw new IllegalArgumentException(
                "La scène " + sceneId + " est de type " + type + " : elle ne porte pas de média.");
        }

        GamesMediaStoragePort.ResourceType resourceType = type == SceneMediaType.VIDEO
            ? GamesMediaStoragePort.ResourceType.VIDEO
            : GamesMediaStoragePort.ResourceType.IMAGE;

        GamesMediaStoragePort.StoredMedia stored =
            storage.upload(content, filename, resourceType);

        return scenes.attachMedia(
            sceneId, stored.url(), stored.publicId(), altText, transcript);
    }
}
