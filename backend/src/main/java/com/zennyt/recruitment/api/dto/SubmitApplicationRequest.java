package com.zennyt.recruitment.api.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** DTO de requête : soumission de candidature. */
public record SubmitApplicationRequest(
    @NotNull UUID jobId,
    String coverLetter
) {}
