package com.zennyt.engagement.application.port;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** File durable locale pour rejouer les événements Recruitment échoués côté Engagement. */
public interface ApplicationEventRetryStore {
    record PendingEvent(DomainEvent event, int attempts) {}

    void enqueue(DomainEvent event, String lastError);
    List<PendingEvent> findDue(Instant now, int limit);
    void delete(UUID eventId);
    void reschedule(UUID eventId, Instant nextAttemptAt, String lastError);
}
