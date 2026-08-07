package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.util.Optional;
import java.util.UUID;

public interface SoftSkillsSummaryRepository {
    SoftSkillsSummary save(SoftSkillsSummary summary);

    Optional<SoftSkillsSummary> findByCandidateIdAndAudience(UUID candidateId, ResumeAudience audience);
}
