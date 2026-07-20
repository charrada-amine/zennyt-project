package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface JpaHardSkillsSummaryRepository extends JpaRepository<HardSkillsSummaryEntity, UUID> {
    Optional<HardSkillsSummaryEntity> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
}
