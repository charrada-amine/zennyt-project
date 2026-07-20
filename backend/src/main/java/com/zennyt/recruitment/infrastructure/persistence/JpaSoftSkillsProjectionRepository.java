package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaSoftSkillsProjectionRepository
        extends JpaRepository<SoftSkillsProjectionEntity, UUID> {

    Optional<SoftSkillsProjectionEntity> findByCandidateIdAndModule(UUID candidateId, String module);

    List<SoftSkillsProjectionEntity> findByCandidateId(UUID candidateId);

    @Query("select projection.candidateId from SoftSkillsProjectionEntity projection " +
           "group by projection.candidateId order by max(projection.updatedAt) desc")
    List<UUID> findCandidateIds(Pageable pageable);
}
