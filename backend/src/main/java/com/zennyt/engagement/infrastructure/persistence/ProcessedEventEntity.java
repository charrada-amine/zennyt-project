package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "processed_events", schema = "engagement")
class ProcessedEventEntity {
    @Id private UUID eventId;
    @Column(nullable = false) private Instant processedAt;

    protected ProcessedEventEntity() {}

    ProcessedEventEntity(UUID eventId, Instant processedAt) {
        this.eventId = eventId;
        this.processedAt = processedAt;
    }

    UUID getEventId() { return eventId; }
    Instant getProcessedAt() { return processedAt; }
}
