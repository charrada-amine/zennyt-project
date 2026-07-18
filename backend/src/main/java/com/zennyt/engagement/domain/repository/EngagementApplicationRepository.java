package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.EngagementApplication;

import java.util.Optional;
import java.util.UUID;

public interface EngagementApplicationRepository {
    Optional<EngagementApplication> findById(UUID applicationId);

    /** Insère ou met à jour la projection (idempotent par application_id). */
    void upsert(EngagementApplication projection);
}
