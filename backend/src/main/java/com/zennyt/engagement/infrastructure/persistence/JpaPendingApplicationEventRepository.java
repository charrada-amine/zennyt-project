package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

interface JpaPendingApplicationEventRepository
        extends JpaRepository<PendingApplicationEventEntity, UUID> {

    List<PendingApplicationEventEntity> findByNextAttemptAtLessThanEqualOrderByNextAttemptAtAsc(
        Instant now, Pageable pageable);

    @Modifying
    @Query(value = """
        INSERT INTO engagement.pending_application_events(
            event_id, event_type, payload, attempts, next_attempt_at,
            last_error, created_at, updated_at)
        VALUES (:eventId, :eventType, :payload, 0, :now, :lastError, :now, :now)
        ON CONFLICT (event_id) DO UPDATE SET
            payload = EXCLUDED.payload,
            last_error = EXCLUDED.last_error,
            next_attempt_at = EXCLUDED.next_attempt_at,
            updated_at = EXCLUDED.updated_at
        """, nativeQuery = true)
    int enqueue(@Param("eventId") UUID eventId,
                @Param("eventType") String eventType,
                @Param("payload") String payload,
                @Param("lastError") String lastError,
                @Param("now") Instant now);

    @Modifying
    @Query(value = """
        UPDATE engagement.pending_application_events
        SET attempts = attempts + 1,
            next_attempt_at = :nextAttemptAt,
            last_error = :lastError,
            updated_at = :now
        WHERE event_id = :eventId
        """, nativeQuery = true)
    int reschedule(@Param("eventId") UUID eventId,
                   @Param("nextAttemptAt") Instant nextAttemptAt,
                   @Param("lastError") String lastError,
                   @Param("now") Instant now);
}
