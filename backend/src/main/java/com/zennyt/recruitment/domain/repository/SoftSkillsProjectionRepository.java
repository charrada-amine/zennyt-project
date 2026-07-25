package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.SoftSkillsProjection;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SoftSkillsProjectionRepository {
    SoftSkillsProjection save(SoftSkillsProjection projection);
    Optional<SoftSkillsProjection> findByCandidateIdAndModule(UUID candidateId, String module);
    List<SoftSkillsProjection> findByCandidateId(UUID candidateId);
    List<UUID> findCandidateIds(int limit);
}
