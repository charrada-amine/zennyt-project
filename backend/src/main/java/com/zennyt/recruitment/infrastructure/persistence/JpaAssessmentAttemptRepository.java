package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
import java.util.List;

public interface JpaAssessmentAttemptRepository extends JpaRepository<AssessmentAttemptEntity, UUID> {
    boolean existsByCandidateIdAndAssessmentIdAndJobOfferId(UUID candidateId, UUID assessmentId, UUID jobOfferId);
    Page<AssessmentAttemptEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    List<AssessmentAttemptEntity> findAllByJobOfferId(UUID jobOfferId);
    List<AssessmentAttemptEntity> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    long countByJobOfferId(UUID jobOfferId);
}
