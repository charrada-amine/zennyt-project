package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Assessment;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository d'évaluations.
 */
public interface AssessmentRepository {

    Assessment save(Assessment assessment);

    Optional<Assessment> findById(UUID id);

    void deleteById(UUID id);

    /** Évaluations créées par un recruteur. */
    List<Assessment> findByRecruiterId(UUID recruiterId, int page, int size);

    long countByRecruiterId(UUID recruiterId);

    /** Évaluations requises pour une offre (via assessmentIds de l'offre). */
    List<Assessment> findByIdIn(List<UUID> ids);
}
