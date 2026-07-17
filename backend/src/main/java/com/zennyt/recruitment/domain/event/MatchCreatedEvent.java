package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un match mutuel est créé (les deux parties ont swipé LIKE). */
public record MatchCreatedEvent(
    UUID eventId, Instant occurredAt,
    UUID matchId, UUID candidateId, UUID jobOfferId, UUID recruiterId
) implements DomainEvent {

    public static MatchCreatedEvent of(UUID matchId, UUID candidateId, UUID jobOfferId, UUID recruiterId) {
        return new MatchCreatedEvent(UUID.randomUUID(), Instant.now(), matchId, candidateId, jobOfferId, recruiterId);
    }

    @Override public String eventType() { return "recruitment.match.created"; }
}
