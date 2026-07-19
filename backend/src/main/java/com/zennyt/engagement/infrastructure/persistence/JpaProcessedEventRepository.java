package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

interface JpaProcessedEventRepository extends JpaRepository<ProcessedEventEntity, UUID> {

    /** Claim atomique : 1 si l'événement vient d'être réservé, 0 s'il était déjà traité. */
    @Modifying
    @Query(value = "INSERT INTO engagement.processed_events(event_id, processed_at) " +
        "VALUES (:eventId, :processedAt) ON CONFLICT DO NOTHING", nativeQuery = true)
    int insertIfAbsent(@Param("eventId") UUID eventId, @Param("processedAt") Instant processedAt);
}
