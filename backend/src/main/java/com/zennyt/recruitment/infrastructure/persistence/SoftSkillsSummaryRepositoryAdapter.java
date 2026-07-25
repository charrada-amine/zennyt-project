package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class SoftSkillsSummaryRepositoryAdapter implements SoftSkillsSummaryRepository {
    private final JpaSoftSkillsSummaryRepository jpa;

    public SoftSkillsSummaryRepositoryAdapter(JpaSoftSkillsSummaryRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public SoftSkillsSummary save(SoftSkillsSummary summary) {
        return toDomain(jpa.save(new SoftSkillsSummaryEntity(
            summary.candidateId(), summary.textFr(), summary.textEn(), summary.updatedAt())));
    }

    @Override
    public Optional<SoftSkillsSummary> findByCandidateId(UUID candidateId) {
        return jpa.findById(candidateId).map(this::toDomain);
    }

    private SoftSkillsSummary toDomain(SoftSkillsSummaryEntity entity) {
        return new SoftSkillsSummary(entity.getCandidateId(), entity.getTextFr(),
            entity.getTextEn(), entity.getUpdatedAt());
    }
}
