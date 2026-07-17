package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface JpaFitScoreDismissalRepository
        extends JpaRepository<FitScoreDismissalEntity, FitScoreDismissalId> {
    boolean existsByRecruiterIdAndCandidateIdAndJobOfferId(
        UUID recruiterId, UUID candidateId, UUID jobOfferId);
}
