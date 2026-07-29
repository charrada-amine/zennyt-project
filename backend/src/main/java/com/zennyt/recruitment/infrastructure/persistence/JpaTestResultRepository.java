package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaTestResultRepository extends JpaRepository<TestResultEntity, UUID> {
    Optional<TestResultEntity> findFirstByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    List<TestResultEntity> findByCandidateIdInAndJobOfferIdIn(List<UUID> candidateIds, List<UUID> jobOfferIds);
    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    Page<TestResultEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByJobOfferId(UUID jobOfferId);
    List<TestResultEntity> findAllByJobOfferId(UUID jobOfferId);
}
