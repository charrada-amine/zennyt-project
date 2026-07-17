package com.zennyt.recruitment.domain.repository;

import java.time.Instant;
import java.util.UUID;

public interface FitScoreDismissalRepository {
    void dismiss(UUID recruiterId, UUID candidateId, UUID jobOfferId, Instant dismissedAt);
    boolean isDismissed(UUID recruiterId, UUID candidateId, UUID jobOfferId);
}
