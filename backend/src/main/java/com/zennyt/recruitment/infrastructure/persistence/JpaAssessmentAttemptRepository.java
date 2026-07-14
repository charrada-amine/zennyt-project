package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface JpaAssessmentAttemptRepository extends JpaRepository<AssessmentAttemptEntity, UUID> {
    boolean existsByCandidateIdAndAssessmentIdAndJobOfferId(UUID candidateId, UUID assessmentId, UUID jobOfferId);
    Page<AssessmentAttemptEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByJobOfferId(UUID jobOfferId);
}
