package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.HardSkillsSummary;

import java.util.Optional;
import java.util.UUID;

public interface HardSkillsSummaryRepository {
    HardSkillsSummary save(HardSkillsSummary summary);
    Optional<HardSkillsSummary> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
}
