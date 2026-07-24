package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Lectures de résultats de test (contrat squad web §7.2) : gating candidat
 * ("me"), liste/summary/détail recruteur (propriété de l'offre vérifiée).
 */
@Service
@Transactional(readOnly = true)
public class GetTestResultsUseCase {

    public record Summary(long candidateCount, long passedCount, int successRate) {}

    private final JobOfferRepository jobOffers;
    private final TestResultRepository testResults;

    public GetTestResultsUseCase(JobOfferRepository jobOffers, TestResultRepository testResults) {
        this.jobOffers = jobOffers;
        this.testResults = testResults;
    }

    public Optional<TestResult> getOwnResult(UUID candidateId, UUID jobOfferId) {
        return testResults.findByCandidateIdAndJobOfferId(candidateId, jobOfferId);
    }

    public List<TestResult> listForJob(UUID recruiterId, UUID jobOfferId, String sort, int page, int size) {
        requireOwnedOffer(jobOfferId, recruiterId);
        return testResults.findByJobOfferId(jobOfferId, sort, page, size);
    }

    public long countForJob(UUID recruiterId, UUID jobOfferId) {
        requireOwnedOffer(jobOfferId, recruiterId);
        return testResults.countByJobOfferId(jobOfferId);
    }

    /** Calculé sur l'ensemble complet des résultats, jamais seulement la page courante. */
    public Summary summaryForJob(UUID recruiterId, UUID jobOfferId) {
        requireOwnedOffer(jobOfferId, recruiterId);
        List<TestResult> all = testResults.findAllByJobOfferId(jobOfferId);
        long candidateCount = all.size();
        long passedCount = all.stream()
            .filter(r -> r.status() != TestResultStatus.ABANDONED && r.passed())
            .count();
        int successRate = candidateCount == 0 ? 0 : (int) ((passedCount * 100) / candidateCount);
        return new Summary(candidateCount, passedCount, successRate);
    }

    public TestResult detailForCandidate(UUID recruiterId, UUID jobOfferId, UUID candidateId) {
        requireOwnedOffer(jobOfferId, recruiterId);
        return testResults.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .orElseThrow(() -> new NotFoundException("Résultat introuvable"));
    }

    private JobOffer requireOwnedOffer(UUID jobOfferId, UUID recruiterId) {
        JobOffer offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        return offer;
    }
}
