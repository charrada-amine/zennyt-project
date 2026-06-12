package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/**
 * Émis quand un candidat soumet une candidature.
 *
 * <p>Consommé notamment par le contexte Engagement (notifier le recruteur,
 * créer la conversation) et Analytics (enregistrer l'événement). Le contexte
 * Recruitment ignore totalement qui écoute — c'est le principe du découplage.
 */
public record ApplicationSubmittedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID applicationId,
    UUID candidateId,
    UUID jobId
) implements DomainEvent {

    public static ApplicationSubmittedEvent of(UUID applicationId, UUID candidateId, UUID jobId) {
        return new ApplicationSubmittedEvent(
            UUID.randomUUID(), Instant.now(), applicationId, candidateId, jobId);
    }

    @Override
    public String eventType() {
        return "recruitment.application.submitted";
    }
}
