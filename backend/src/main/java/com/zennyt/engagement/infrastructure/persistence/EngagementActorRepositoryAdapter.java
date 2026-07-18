package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.EngagementActor;
import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class EngagementActorRepositoryAdapter implements EngagementActorRepository {
    private final JpaEngagementActorRepository jpa;

    @Override
    public EngagementActor save(EngagementActor actor) {
        return toDomain(jpa.save(new EngagementActorEntity(
            actor.userId(), actor.role(), actor.active(), actor.displayName(), actor.photoUrl(),
            actor.lastEventAt(), actor.lastEventId())));
    }

    @Override
    public Optional<EngagementActor> findById(UUID userId) {
        return jpa.findById(userId).map(this::toDomain);
    }

    private EngagementActor toDomain(EngagementActorEntity entity) {
        return new EngagementActor(entity.getUserId(), entity.getRole(), entity.isActive(),
            entity.getDisplayName(), entity.getPhotoUrl(), entity.getLastEventAt(),
            entity.getLastEventId());
    }
}
