package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.EngagementActor;

import java.util.Optional;
import java.util.UUID;

public interface EngagementActorRepository {
    EngagementActor save(EngagementActor actor);
    Optional<EngagementActor> findById(UUID userId);
}
