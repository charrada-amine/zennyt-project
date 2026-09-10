package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.EmotionalRadarV2SceneRepository;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Adaptateur JPA des scènes/réponses Emotional Radar V2. */
@Component
public class EmotionalRadarV2SceneRepositoryAdapter
    implements EmotionalRadarV2SceneRepository {

    private final JpaEmotionalRadarV2SceneRepository jpa;

    public EmotionalRadarV2SceneRepositoryAdapter(JpaEmotionalRadarV2SceneRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public List<RadarV2SceneAssignment> findBySessionId(UUID sessionId) {
        return jpa.findBySessionIdOrderBySceneOrderAsc(sessionId).stream()
            .map(EmotionalRadarV2SceneEntity::toDomain)
            .toList();
    }

    @Override
    public Optional<RadarV2SceneAssignment> findBySessionIdAndOrder(
            UUID sessionId, int sceneOrder) {
        return jpa.findBySessionIdAndSceneOrder(sessionId, sceneOrder)
            .map(EmotionalRadarV2SceneEntity::toDomain);
    }

    @Override
    public RadarV2SceneAssignment insert(RadarV2SceneAssignment assignment) {
        if (assignment.answered()) {
            throw new IllegalArgumentException("une nouvelle scène doit être en attente");
        }
        EmotionalRadarV2SceneEntity.SceneId id =
            new EmotionalRadarV2SceneEntity.SceneId(
                assignment.sessionId(), assignment.sceneOrder());
        if (jpa.existsById(id)) {
            throw new IllegalStateException("scène V2 déjà assignée : " + assignment.sceneOrder());
        }
        return jpa.saveAndFlush(EmotionalRadarV2SceneEntity.fromDomain(assignment)).toDomain();
    }

    @Override
    public RadarV2SceneAssignment answer(RadarV2SceneAssignment answeredAssignment) {
        if (!answeredAssignment.answered()) {
            throw new IllegalArgumentException("réponse V2 requise");
        }
        EmotionalRadarV2SceneEntity entity = jpa.findBySessionIdAndSceneOrder(
                answeredAssignment.sessionId(), answeredAssignment.sceneOrder())
            .orElseThrow(() -> new IllegalStateException(
                "scène V2 non assignée : " + answeredAssignment.sceneOrder()));
        entity.applyFirstAnswer(answeredAssignment);
        return jpa.saveAndFlush(entity).toDomain();
    }
}
