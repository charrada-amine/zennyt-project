package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class HardSkillsSummaryRepositoryAdapter implements HardSkillsSummaryRepository {
    private final JpaHardSkillsSummaryRepository jpa;

    public HardSkillsSummaryRepositoryAdapter(JpaHardSkillsSummaryRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public HardSkillsSummary save(HardSkillsSummary summary) {
        return toDomain(jpa.save(new HardSkillsSummaryEntity(summary.id(), summary.candidateId(),
            summary.jobPositionId(), summary.audience(),
            summary.textFr(), summary.textEn(), summary.updatedAt())));
    }

    @Override
    public Optional<HardSkillsSummary> findByCandidateIdAndJobPositionIdAndAudience(
            UUID candidateId, UUID jobPositionId, ResumeAudience audience) {
        if (jobPositionId == null) return Optional.empty();
        return jpa.findByCandidateIdAndJobPositionIdAndAudience(candidateId, jobPositionId, audience)
            .map(this::toDomain);
    }

    private HardSkillsSummary toDomain(HardSkillsSummaryEntity entity) {
        return new HardSkillsSummary(entity.getId(), entity.getCandidateId(), entity.getJobPositionId(),
            entity.getAudience(), entity.getTextFr(), entity.getTextEn(), entity.getUpdatedAt());
    }
}
