package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pending_application_events", schema = "engagement")
class PendingApplicationEventEntity {
    @Id private UUID eventId;
    @Column(nullable = false, length = 100) private String eventType;
    @Column(nullable = false, columnDefinition = "TEXT") private String payload;
    @Column(nullable = false) private int attempts;
    @Column(nullable = false) private Instant nextAttemptAt;
    @Column(columnDefinition = "TEXT") private String lastError;
    @Column(nullable = false) private Instant createdAt;
    @Column(nullable = false) private Instant updatedAt;

    protected PendingApplicationEventEntity() {}

    UUID getEventId() { return eventId; }
    String getEventType() { return eventType; }
    String getPayload() { return payload; }
    int getAttempts() { return attempts; }
    Instant getNextAttemptAt() { return nextAttemptAt; }
    String getLastError() { return lastError; }
    Instant getCreatedAt() { return createdAt; }
    Instant getUpdatedAt() { return updatedAt; }
}
