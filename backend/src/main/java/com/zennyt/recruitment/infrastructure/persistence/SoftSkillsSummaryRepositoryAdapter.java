package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
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
        return toDomain(jpa.save(new SoftSkillsSummaryEntity(summary.candidateId(), summary.audience(),
            summary.textFr(), summary.textEn(), summary.updatedAt())));
    }

    @Override
    public Optional<SoftSkillsSummary> findByCandidateIdAndAudience(UUID candidateId, ResumeAudience audience) {
        return jpa.findByCandidateIdAndAudience(candidateId, audience).map(this::toDomain);
    }

    private SoftSkillsSummary toDomain(SoftSkillsSummaryEntity entity) {
        return new SoftSkillsSummary(entity.getCandidateId(), entity.getAudience(),
            entity.getTextFr(), entity.getTextEn(), entity.getUpdatedAt());
    }
}
