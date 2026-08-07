package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ResumeAudience;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface JpaSoftSkillsSummaryRepository
        extends JpaRepository<SoftSkillsSummaryEntity, SoftSkillsSummaryEntity.Key> {

    Optional<SoftSkillsSummaryEntity> findByCandidateIdAndAudience(UUID candidateId, ResumeAudience audience);
}
