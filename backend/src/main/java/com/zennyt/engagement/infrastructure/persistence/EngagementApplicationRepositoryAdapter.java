package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class EngagementApplicationRepositoryAdapter implements EngagementApplicationRepository {
    private final JpaEngagementApplicationRepository jpa;

    @Override
    public Optional<EngagementApplication> findById(UUID applicationId) {
        return jpa.findById(applicationId).map(this::toDomain);
    }

    @Override
    public void upsert(EngagementApplication projection) {
        EngagementApplicationEntity entity = jpa.findById(projection.applicationId())
            .orElseGet(() -> new EngagementApplicationEntity(
                projection.applicationId(), projection.jobOfferId(), projection.candidateId(),
                projection.recruiterId(), projection.jobTitle(),
                projection.lastEventId(), projection.lastEventAt()));
        entity.update(projection.jobOfferId(), projection.candidateId(), projection.recruiterId(),
            projection.jobTitle(), projection.lastEventId(), projection.lastEventAt());
        jpa.save(entity);
    }

    private EngagementApplication toDomain(EngagementApplicationEntity entity) {
        return new EngagementApplication(entity.getApplicationId(), entity.getJobOfferId(),
            entity.getCandidateId(), entity.getRecruiterId(), entity.getJobTitle(),
            entity.getLastEventId(), entity.getLastEventAt());
    }
}
