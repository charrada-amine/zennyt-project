package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.SoftSkillsProjection;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SoftSkillsProjectionRepository {
    SoftSkillsProjection save(SoftSkillsProjection projection);
    Optional<SoftSkillsProjection> findByCandidateIdAndModule(UUID candidateId, String module);
    List<SoftSkillsProjection> findByCandidateId(UUID candidateId);
    /** Variante par lot de {@link #findByCandidateId} — une seule requête pour tout un lot de recalcul. */
    List<SoftSkillsProjection> findByCandidateIds(List<UUID> candidateIds);
    List<UUID> findCandidateIds(int limit);
}
