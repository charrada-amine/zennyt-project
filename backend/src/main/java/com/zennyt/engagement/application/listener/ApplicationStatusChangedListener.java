package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Notifie le candidat d'un changement de statut, de façon idempotente : un rejeu
 * du même {@code eventId} ne recrée pas la notification (claim refusé). Traité
 * après commit dans une transaction Engagement indépendante.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ApplicationStatusChangedListener {
    private final ApplicationStatusChangedProjector projector;
    private final ApplicationEventRetryStore retryStore;

    @TransactionalEventListener
    public void on(ApplicationStatusChangedEvent event) {
        try {
            projector.project(event);
        } catch (RuntimeException failure) {
            log.error("Projection de statut échouée, mise en retry de l'événement {}",
                event.eventId(), failure);
            enqueueWithoutBreakingRecruitment(event, failure);
        }
    }

    private void enqueueWithoutBreakingRecruitment(
            ApplicationStatusChangedEvent event, RuntimeException failure) {
        try {
            retryStore.enqueue(event, failure.getMessage());
        } catch (RuntimeException retryFailure) {
            log.error("Impossible de persister le retry Engagement pour l'événement {}",
                event.eventId(), retryFailure);
        }
    }
}
