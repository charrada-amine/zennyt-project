package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Repository Spring Data interne des affectations Emotional Radar V2. */
public interface JpaEmotionalRadarV2SceneRepository extends
    JpaRepository<EmotionalRadarV2SceneEntity, EmotionalRadarV2SceneEntity.SceneId> {

    List<EmotionalRadarV2SceneEntity> findBySessionIdOrderBySceneOrderAsc(UUID sessionId);

    Optional<EmotionalRadarV2SceneEntity> findBySessionIdAndSceneOrder(
        UUID sessionId, int sceneOrder);
}
