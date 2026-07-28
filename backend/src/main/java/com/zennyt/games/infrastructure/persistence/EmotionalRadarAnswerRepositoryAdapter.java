package com.zennyt.games.infrastructure.persistence;

import com.zennyt.games.domain.repository.EmotionalRadarAnswerRepository;
import com.zennyt.games.domain.vo.EmotionalRadarAnswer;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/** Implémente le port du domaine ; mappe VO ⇄ entité JPA. */
@Component
public class EmotionalRadarAnswerRepositoryAdapter implements EmotionalRadarAnswerRepository {

    private final JpaEmotionalRadarAnswerRepository jpa;

    public EmotionalRadarAnswerRepositoryAdapter(JpaEmotionalRadarAnswerRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public EmotionalRadarAnswer save(EmotionalRadarAnswer answer) {
        // La clé composite (session, scène) fait de save() un upsert : re-valider
        // une scène après une coupure réseau remplace la ligne, sans doubler les points.
        return jpa.save(EmotionalRadarAnswerEntity.fromDomain(answer)).toDomain();
    }

    @Override
    public List<EmotionalRadarAnswer> findBySessionId(UUID sessionId) {
        return jpa.findBySessionIdOrderBySceneOrderAsc(sessionId).stream()
            .map(EmotionalRadarAnswerEntity::toDomain)
            .toList();
    }

    @Override
    public boolean existsBySessionIdAndSceneId(UUID sessionId, UUID sceneId) {
        return jpa.existsBySessionIdAndSceneId(sessionId, sceneId);
    }
}
