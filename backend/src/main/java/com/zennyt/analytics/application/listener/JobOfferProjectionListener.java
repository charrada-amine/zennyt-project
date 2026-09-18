package com.zennyt.analytics.application.listener;

import com.zennyt.analytics.domain.repository.AnalyticsProjectionWriter;
import com.zennyt.recruitment.domain.event.JobOfferCreatedEvent;
import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Maintient la projection des offres pour les statistiques recruteur. Analytics
 * n'appelle jamais Recruitment : il ne fait qu'écouter ses Domain Events.
 */
@Component
public class JobOfferProjectionListener {

    private final AnalyticsProjectionWriter writer;

    public JobOfferProjectionListener(AnalyticsProjectionWriter writer) {
        this.writer = writer;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(JobOfferCreatedEvent event) {
        writer.upsertJobOffer(event.jobOfferId(), event.recruiterId(), "DRAFT", event.occurredAt());
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(JobOfferStatusChangedEvent event) {
        writer.updateJobOfferStatus(event.jobOfferId(), event.newStatus().name(), event.occurredAt());
    }
}
