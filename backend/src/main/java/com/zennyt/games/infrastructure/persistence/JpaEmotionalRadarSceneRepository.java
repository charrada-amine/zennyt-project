package com.zennyt.games.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/** Repository Spring Data technique des scènes « Emotional Radar ». */
public interface JpaEmotionalRadarSceneRepository
    extends JpaRepository<EmotionalRadarSceneEntity, UUID> {

    /** Scènes jouables, dans l'ordre de la session. */
    List<EmotionalRadarSceneEntity> findByActiveTrueOrderBySceneOrderAsc();
}
