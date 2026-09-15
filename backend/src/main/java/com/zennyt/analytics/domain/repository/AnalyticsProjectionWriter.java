package com.zennyt.analytics.domain.repository;

import java.time.Instant;
import java.util.UUID;

/**
 * Écriture du read-model Analytics, alimentée par les Domain Events des autres
 * contextes. Idempotente par construction (upsert d'offre, insertion d'activité).
 */
public interface AnalyticsProjectionWriter {

    void upsertJobOffer(UUID jobOfferId, UUID recruiterId, String status, Instant occurredAt);

    void updateJobOfferStatus(UUID jobOfferId, String status, Instant occurredAt);

    void recordCandidateActivity(UUID candidateId, UUID jobOfferId, String kind, Instant occurredAt);
}
