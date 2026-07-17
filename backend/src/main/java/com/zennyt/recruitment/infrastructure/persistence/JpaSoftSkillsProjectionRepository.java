package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface JpaSoftSkillsProjectionRepository
        extends JpaRepository<SoftSkillsProjectionEntity, UUID> {
    @Query("select projection.candidateId from SoftSkillsProjectionEntity projection order by projection.updatedAt desc")
    List<UUID> findCandidateIds(Pageable pageable);
}
