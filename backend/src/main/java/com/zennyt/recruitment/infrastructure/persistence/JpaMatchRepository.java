package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface JpaMatchRepository extends JpaRepository<MatchEntity, UUID> {
    Page<MatchEntity> findByCandidateId(UUID candidateId, Pageable pageable);
    Optional<MatchEntity> findFirstByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    long countByCandidateId(UUID candidateId);
    Page<MatchEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByJobOfferId(UUID jobOfferId);
}
