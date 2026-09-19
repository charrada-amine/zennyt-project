package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pending_application_events", schema = "engagement",
    indexes = @Index(name = "idx_engagement_pending_events_due", columnList = "next_attempt_at, event_id"))
@Check(name = "pending_application_events_attempts_check", constraints = "attempts >= 0")
class PendingApplicationEventEntity {
    @Id private UUID eventId;
    @Column(nullable = false, length = 100) private String eventType;
    @Column(nullable = false, length = Length.LONG32) private String payload;
    @ColumnDefault("0") @Column(nullable = false) private int attempts;
    @Column(nullable = false) private Instant nextAttemptAt;
    @Column(length = Length.LONG32) private String lastError;
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
