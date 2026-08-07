package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/**
 * Émis quand un match mutuel est créé (les deux parties ont swipé RIGHT).
 *
 * <p>Porte {@code jobTitle} pour qu'Engagement puisse construire une
 * conversation et une notification sans appel direct au module Recruitment —
 * c'est le point d'accroche qui remplace l'ancien {@code ApplicationSubmittedEvent}
 * (entité Application supprimée, contrat squad web §5/§6).
 */
public record MatchCreatedEvent(
    UUID eventId, Instant occurredAt,
    UUID matchId, UUID candidateId, UUID jobOfferId, UUID recruiterId, String jobTitle
) implements DomainEvent {

    public static MatchCreatedEvent of(UUID matchId, UUID candidateId, UUID jobOfferId,
                                       UUID recruiterId, String jobTitle) {
        return new MatchCreatedEvent(UUID.randomUUID(), Instant.now(), matchId, candidateId, jobOfferId,
            recruiterId, jobTitle);
    }

    @Override public String eventType() { return "recruitment.match.created"; }
}
