package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ResumeAudience;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface JpaHardSkillsSummaryRepository extends JpaRepository<HardSkillsSummaryEntity, UUID> {

    Optional<HardSkillsSummaryEntity> findByCandidateIdAndJobPositionIdAndAudience(
        UUID candidateId, UUID jobPositionId, ResumeAudience audience);
}
