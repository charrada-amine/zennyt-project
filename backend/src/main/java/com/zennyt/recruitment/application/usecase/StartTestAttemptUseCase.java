package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.TestAttemptRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : démarrer une tentative de test de compétences (contrat squad
 * web §7.2-7.4). 404 si l'offre n'a pas d'évaluation liée ; 409 si un résultat
 * existe déjà pour cette paire (candidateId, jobOfferId), quel que soit son
 * statut — une seule tentative par candidat par offre, pour toujours.
 */
@Service
@Transactional
public class StartTestAttemptUseCase {

    private final JobOfferRepository jobOffers;
    private final AssessmentRepository assessments;
    private final TestResultRepository testResults;
    private final TestAttemptRepository testAttempts;

    public StartTestAttemptUseCase(JobOfferRepository jobOffers, AssessmentRepository assessments,
                                   TestResultRepository testResults, TestAttemptRepository testAttempts) {
        this.jobOffers = jobOffers;
        this.assessments = assessments;
        this.testResults = testResults;
        this.testAttempts = testAttempts;
    }

    public TestAttempt execute(UUID candidateId, UUID jobOfferId) {
        JobOffer offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (offer.assessmentId() == null) {
            throw new NotFoundException("NO_ASSESSMENT_LINKED", "Aucune évaluation liée à cette offre");
        }
        if (testResults.existsByCandidateIdAndJobOfferId(candidateId, jobOfferId)) {
            throw new ConflictException("ATTEMPT_ALREADY_CONSUMED",
                "Une tentative a déjà été consommée pour cette offre");
        }
        Assessment assessment = assessments.findById(offer.assessmentId())
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable"));

        TestAttempt attempt = TestAttempt.start(jobOfferId, assessment.id(), candidateId,
            assessment.questions(), assessment.timeLimitSeconds());
        return testAttempts.save(attempt);
    }
}
