package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Précalcule une offre nouvellement publiée pour les candidats déjà projetés. */
@Component
public class JobOfferFitScoreListener {
    private final RecomputeFitScoresUseCase recompute;
    private final FitScoreRecomputeWorker worker;

    public JobOfferFitScoreListener(RecomputeFitScoresUseCase recompute,
                                    FitScoreRecomputeWorker worker) {
        this.recompute = recompute;
        this.worker = worker;
    }

    @Async("recruitmentFitScoreExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(JobOfferStatusChangedEvent event) {
        if (event.newStatus() == JobOfferStatus.ACTIVE) {
            recompute.pairsForOffer(event.jobOfferId()).forEach(worker::submit);
        }
    }
}
