package com.zennyt.games.domain.repository;

import com.zennyt.games.domain.vo.RadarV2SceneAssignment;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Port de persistance des affectations/réponses immuables Radar V2. */
public interface EmotionalRadarV2SceneRepository {

    List<RadarV2SceneAssignment> findBySessionId(UUID sessionId);

    Optional<RadarV2SceneAssignment> findBySessionIdAndOrder(UUID sessionId, int sceneOrder);

    /** Insère une nouvelle scène en attente ; n'écrase jamais une scène existante. */
    RadarV2SceneAssignment insert(RadarV2SceneAssignment assignment);

    /** Enregistre la première et unique réponse d'une scène en attente. */
    RadarV2SceneAssignment answer(RadarV2SceneAssignment answeredAssignment);
}
