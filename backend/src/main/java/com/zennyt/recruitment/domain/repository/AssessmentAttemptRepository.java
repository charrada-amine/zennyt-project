package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.AssessmentAttempt;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de tentatives d'évaluation.
 */
public interface AssessmentAttemptRepository {

    AssessmentAttempt save(AssessmentAttempt attempt);

    Optional<AssessmentAttempt> findById(UUID id);

    /** Vérifie l'unicité : une seule tentative par (candidat, assessment, offre). */
    boolean existsByCandidateIdAndAssessmentIdAndJobOfferId(UUID candidateId, UUID assessmentId, UUID jobOfferId);

    /** Résultats de tous les candidats pour une offre (vue recruteur). */
    List<AssessmentAttempt> findByJobOfferId(UUID jobOfferId, int page, int size);

    List<AssessmentAttempt> findAllByJobOfferId(UUID jobOfferId);

    /** Tentatives d'un candidat pour une offre (résumé IA hard skills). */
    List<AssessmentAttempt> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    long countByJobOfferId(UUID jobOfferId);
}
