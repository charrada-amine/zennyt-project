package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Construit l'état Engagement à partir de l'événement public de Recruitment, sans
 * appel direct au module.
 *
 * <p>Traité <b>après commit</b> de la transaction Recruitment, dans une transaction
 * Engagement indépendante ({@code REQUIRES_NEW}). L'ensemble claim + projection +
 * conversation + notification est atomique : un rejeu du même {@code eventId} est
 * un no-op complet (claim refusé), et un échec partiel annule le claim pour
 * permettre une nouvelle tentative.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ApplicationSubmittedListener {
    private final ApplicationSubmittedProjector projector;
    private final ApplicationEventRetryStore retryStore;

    @TransactionalEventListener
    public void on(ApplicationSubmittedEvent event) {
        try {
            projector.project(event);
        } catch (RuntimeException failure) {
            log.error("Projection de soumission échouée, mise en retry de l'événement {}",
                event.eventId(), failure);
            enqueueWithoutBreakingRecruitment(event, failure);
        }
    }

    private void enqueueWithoutBreakingRecruitment(ApplicationSubmittedEvent event, RuntimeException failure) {
        try {
            retryStore.enqueue(event, failure.getMessage());
        } catch (RuntimeException retryFailure) {
            log.error("Impossible de persister le retry Engagement pour l'événement {}",
                event.eventId(), retryFailure);
        }
    }
}
