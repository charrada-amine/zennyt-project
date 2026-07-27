package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class JobPositionRepositoryAdapter implements JobPositionRepository {
    private final JpaJobPositionRepository jpa;

    public JobPositionRepositoryAdapter(JpaJobPositionRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public JobPosition save(JobPosition position) {
        return toDomain(jpa.save(new JobPositionEntity(position.id(), position.name(), position.sector(),
            position.profileType(), position.calibrated(), position.status(), position.proposedByRecruiterId(),
            position.juniorLabel(), position.midLabel(), position.seniorLabel(), position.executiveLabel(),
            position.createdAt(), position.embedding(), position.suggestedProfileType())));
    }

    @Override
    public Optional<JobPosition> findById(UUID id) {
        return jpa.findById(id).map(this::toDomain);
    }

    @Override
    public List<JobPosition> findByStatus(JobPositionStatus status, String sector) {
        var entities = sector != null ? jpa.findByStatusAndSector(status, sector) : jpa.findByStatus(status);
        return entities.stream().map(this::toDomain).toList();
    }

    @Override
    public boolean existsByNameAndSector(String name, String sector) {
        return jpa.existsByNameAndSector(name, sector);
    }

    @Override
    public List<JobPosition> findByEmbeddingIsNull() {
        return jpa.findByEmbeddingIsNull().stream().map(this::toDomain).toList();
    }

    @Override
    public List<JobPosition> findByIds(List<UUID> ids) {
        return jpa.findAllById(ids).stream().map(this::toDomain).toList();
    }

    private JobPosition toDomain(JobPositionEntity entity) {
        return JobPosition.rehydrate(entity.getId(), entity.getName(), entity.getSector(),
            entity.getProfileType(), entity.isCalibrated(), entity.getStatus(),
            entity.getProposedByRecruiterId(), entity.getJuniorLabel(), entity.getMidLabel(),
            entity.getSeniorLabel(), entity.getExecutiveLabel(), entity.getCreatedAt(), entity.getEmbedding(),
            entity.getSuggestedProfileType());
    }
}
