package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Précalcule une offre nouvellement publiée pour les candidats déjà projetés. */
@Component
public class JobOfferFitScoreListener {
    private final RecomputeFitScoresUseCase recompute;
    private final FitScoreEnqueuer enqueuer;

    public JobOfferFitScoreListener(RecomputeFitScoresUseCase recompute,
                                    FitScoreEnqueuer enqueuer) {
        this.recompute = recompute;
        this.enqueuer = enqueuer;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(JobOfferStatusChangedEvent event) {
        if (event.newStatus() == JobOfferStatus.ACTIVE) {
            // Enfilé plutôt que soumis paire par paire à un exécuteur en mémoire : le
            // travail survit à un redémarrage, se dédoublonne si l'offre est republiée, et
            // n'est plus borné par la capacité d'une file en RAM.
            enqueuer.enqueueUrgent(recompute.pairsForOffer(event.jobOfferId()).stream()
                .map(pair -> new CandidateOfferPair(pair.candidateId(), pair.offer().id()))
                .toList());
        }
    }
}
