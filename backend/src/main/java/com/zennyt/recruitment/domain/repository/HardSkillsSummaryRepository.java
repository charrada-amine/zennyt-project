package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.util.Optional;
import java.util.UUID;

public interface HardSkillsSummaryRepository {
    HardSkillsSummary save(HardSkillsSummary summary);

    /** Le résumé hard skills est indexé par métier depuis D1, plus par offre. */
    Optional<HardSkillsSummary> findByCandidateIdAndJobPositionIdAndAudience(
        UUID candidateId, UUID jobPositionId, ResumeAudience audience);
}
