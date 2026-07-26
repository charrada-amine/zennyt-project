package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Recalcule le Fit Score de la paire (candidat, offre) à la soumission d'une
 * tentative de test de compétences (D2, PLAN_FITSCORE_V3.md) — avant cet
 * événement, poidsHard=0 (soft-only, cf. DeterministicFitScoreCalculator) ;
 * une fois le test complété, le score se recalcule avec la composante hard.
 *
 * <p>Ne cible que l'offre concernée (contrairement à {@link GameSoftSkillsListener},
 * qui recalcule toutes les paires du candidat) : un résultat de test est
 * spécifique à l'offre dont le QCM a été passé.
 */
@Component
public class TestResultRecomputeListener {
    private static final Logger log = LoggerFactory.getLogger(TestResultRecomputeListener.class);

    private final JobOfferRepository offers;
    private final FitScoreRecomputeWorker worker;

    public TestResultRecomputeListener(JobOfferRepository offers, FitScoreRecomputeWorker worker) {
        this.offers = offers;
        this.worker = worker;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(TestResultCompletedEvent event) {
        offers.findById(event.jobOfferId()).ifPresentOrElse(
            offer -> worker.submit(new RecomputeFitScoresUseCase.Pair(event.candidateId(), offer)),
            () -> log.warn("[FitScore] Offre introuvable pour le résultat de test {}", event.testResultId()));
    }
}
