package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.TestResult;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Port du repository de résultats de test de compétences. */
public interface TestResultRepository {

    TestResult save(TestResult result);

    Optional<TestResult> findById(UUID id);

    Optional<TestResult> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    /** Page de résultats pour une offre (vue liste recruteur). */
    List<TestResult> findByJobOfferId(UUID jobOfferId, int page, int size);

    long countByJobOfferId(UUID jobOfferId);

    /** Ensemble complet des résultats d'une offre — pour l'agrégat summary, jamais paginé. */
    List<TestResult> findAllByJobOfferId(UUID jobOfferId);
}
