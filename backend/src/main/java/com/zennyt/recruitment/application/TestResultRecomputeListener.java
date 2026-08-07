package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.List;
import java.util.UUID;

/**
 * Recalcule les Fit Scores impactés par la soumission d'un test de compétences
 * (D2, PLAN_FITSCORE_V3.md) — avant cet événement, poidsHard=0 (soft-only, cf.
 * {@code DeterministicFitScoreCalculator}) ; une fois le test complété, le score se
 * recalcule avec la composante hard.
 *
 * <p><b>D1 — la portée n'est plus la seule paire.</b> Ce listener ne ciblait que l'offre
 * dont le QCM avait été passé, au motif qu'« un résultat de test est spécifique à
 * l'offre ». Ce motif est tombé : le sous-score hard s'estime désormais sur tout
 * l'historique du candidat sur le <b>métier</b>, donc un test soumis ici rend faux les
 * scores du candidat sur <b>toutes</b> les offres ACTIVE du même métier.
 *
 * <p>Deux chemins volontairement distincts : l'offre testée part en direct (c'est celle
 * que le recruteur va regarder dans la seconde), les offres sœurs passent par la file —
 * elles peuvent être nombreuses, et la file existe précisément pour absorber ce genre de
 * rafale sans monopoliser le pool d'exécution.
 */
@Component
public class TestResultRecomputeListener {
    private static final Logger log = LoggerFactory.getLogger(TestResultRecomputeListener.class);

    private final JobOfferRepository offers;
    private final FitScoreRecomputeWorker worker;
    private final FitScoreEnqueuer enqueuer;

    public TestResultRecomputeListener(JobOfferRepository offers, FitScoreRecomputeWorker worker,
                                       FitScoreEnqueuer enqueuer) {
        this.offers = offers;
        this.worker = worker;
        this.enqueuer = enqueuer;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(TestResultCompletedEvent event) {
        offers.findById(event.jobOfferId()).ifPresentOrElse(
            offer -> {
                worker.submit(new RecomputeFitScoresUseCase.Pair(event.candidateId(), offer));
                enqueuerLesOffresDuMemeMetier(event.candidateId(), offer);
            },
            () -> log.warn("[FitScore] Offre introuvable pour le résultat de test {}", event.testResultId()));
    }

    private void enqueuerLesOffresDuMemeMetier(UUID candidateId, JobOffer offreTestee) {
        UUID jobPositionId = offreTestee.jobPositionId();
        if (jobPositionId == null) return; // offre héritée sans métier : rien à propager
        List<CandidateOfferPair> soeurs = offers.findActiveIdsByJobPositionId(jobPositionId).stream()
            .filter(id -> !id.equals(offreTestee.id()))
            .map(id -> new CandidateOfferPair(candidateId, id))
            .toList();
        enqueuer.enqueueUrgent(soeurs);
    }
}
