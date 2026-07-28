package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/** Repository Spring Data technique des réponses notées « Emotional Radar ». */
public interface JpaEmotionalRadarAnswerRepository
    extends JpaRepository<EmotionalRadarAnswerEntity, EmotionalRadarAnswerEntity.AnswerId> {

    List<EmotionalRadarAnswerEntity> findBySessionIdOrderBySceneOrderAsc(UUID sessionId);

    boolean existsBySessionIdAndSceneId(UUID sessionId, UUID sceneId);
}
