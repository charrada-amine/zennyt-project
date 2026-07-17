package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.RecruitmentActor;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class RecruitmentActorRepositoryAdapter implements RecruitmentActorRepository {
    private final JpaRecruitmentActorRepository jpa;

    @Override
    public Optional<RecruitmentActor> findById(UUID publicUserId) {
        return jpa.findById(publicUserId).map(this::toDomain);
    }

    @Override
    public RecruitmentActor save(RecruitmentActor actor) {
        RecruitmentActorEntity entity = new RecruitmentActorEntity(
            actor.publicUserId(), actor.role(), actor.active(),
            actor.lastEventAt(), actor.lastEventId());
        return toDomain(jpa.save(entity));
    }

    private RecruitmentActor toDomain(RecruitmentActorEntity entity) {
        return new RecruitmentActor(entity.getPublicUserId(), entity.getRole(), entity.isActive(),
            entity.getLastEventAt(), entity.getLastEventId());
    }
}
