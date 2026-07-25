package com.zennyt.recruitment.domain.event;

import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un swipe est enregistré (candidat ou recruteur). */
public record SwipeRecordedEvent(
    UUID eventId, Instant occurredAt,
    UUID swipeId, UUID jobOfferId, UUID candidateId, SwipeSide side, SwipeDirection direction
) implements DomainEvent {

    public static SwipeRecordedEvent of(UUID swipeId, UUID jobOfferId, UUID candidateId,
                                        SwipeSide side, SwipeDirection direction) {
        return new SwipeRecordedEvent(UUID.randomUUID(), Instant.now(), swipeId, jobOfferId, candidateId, side, direction);
    }

    @Override public String eventType() { return "recruitment.swipe.recorded"; }
}
