package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.Application;
import java.time.Instant;
import java.util.UUID;

/** DTO de réponse : représentation API d'une candidature. */
public record ApplicationResponse(
    UUID id,
    UUID candidateId,
    UUID jobId,
    String currentStatus,
    Instant appliedAt,
    Instant updatedAt
) {
    public static ApplicationResponse from(Application a) {
        return new ApplicationResponse(
            a.id(), a.candidateId(), a.jobId(),
            a.status().name(), a.appliedAt(), a.updatedAt());
    }
}
