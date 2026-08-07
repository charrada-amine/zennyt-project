package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class SoftSkillsProjectionRepositoryAdapter implements SoftSkillsProjectionRepository {
    private final JpaSoftSkillsProjectionRepository jpa;

    public SoftSkillsProjectionRepositoryAdapter(JpaSoftSkillsProjectionRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public SoftSkillsProjection save(SoftSkillsProjection projection) {
        return toDomain(jpa.save(new SoftSkillsProjectionEntity(
            projection.id(), projection.candidateId(), projection.module(),
            projection.score(), projection.coverageRatio(), projection.updatedAt())));
    }

    @Override
    public Optional<SoftSkillsProjection> findByCandidateIdAndModule(UUID candidateId, String module) {
        return jpa.findByCandidateIdAndModule(candidateId, module).map(this::toDomain);
    }

    @Override
    public List<SoftSkillsProjection> findByCandidateId(UUID candidateId) {
        return jpa.findByCandidateId(candidateId).stream().map(this::toDomain).toList();
    }

    @Override
    public List<SoftSkillsProjection> findByCandidateIds(List<UUID> candidateIds) {
        if (candidateIds.isEmpty()) return List.of();
        return jpa.findByCandidateIdIn(candidateIds).stream().map(this::toDomain).toList();
    }

    @Override
    public List<UUID> findCandidateIds(int limit) {
        return jpa.findCandidateIds(PageRequest.of(0, Math.max(1, limit)));
    }

    private SoftSkillsProjection toDomain(SoftSkillsProjectionEntity entity) {
        return new SoftSkillsProjection(entity.getId(), entity.getCandidateId(),
            entity.getModule(), entity.getScore(), entity.getCoverageRatio(), entity.getUpdatedAt());
    }
}
