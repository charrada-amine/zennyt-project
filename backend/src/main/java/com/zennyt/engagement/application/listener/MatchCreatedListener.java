package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
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
 *
 * <p>Remplace {@code ApplicationSubmittedListener} : écoute désormais
 * {@code MatchCreatedEvent} (le dépôt de candidature n'existe plus, un match
 * mutuel RIGHT/RIGHT est le nouveau déclencheur de conversation).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class MatchCreatedListener {
    private final MatchCreatedProjector projector;
    private final ApplicationEventRetryStore retryStore;

    @TransactionalEventListener
    public void on(MatchCreatedEvent event) {
        try {
            projector.project(event);
        } catch (RuntimeException failure) {
            log.error("Projection de match échouée, mise en retry de l'événement {}",
                event.eventId(), failure);
            enqueueWithoutBreakingRecruitment(event, failure);
        }
    }

    private void enqueueWithoutBreakingRecruitment(MatchCreatedEvent event, RuntimeException failure) {
        try {
            retryStore.enqueue(event, failure.getMessage());
        } catch (RuntimeException retryFailure) {
            log.error("Impossible de persister le retry Engagement pour l'événement {}",
                event.eventId(), retryFailure);
        }
    }
}
