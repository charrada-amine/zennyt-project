package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import java.time.Instant;
import java.util.UUID;

/** DTO de réponse pour une candidature. */
public record ApplicationResponse(
    UUID id, UUID candidateId, UUID jobOfferId,
    ApplicationStatus status, Instant appliedAt, Instant updatedAt
) {
    public static ApplicationResponse from(Application a) {
        return new ApplicationResponse(a.id(), a.candidateId(), a.jobOfferId(),
            a.status(), a.appliedAt(), a.updatedAt());
    }
}
