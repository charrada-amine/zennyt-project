package com.zennyt.recruitment.api.dto;

import java.util.UUID;

/** DTO de requête pour soumettre une candidature. */
public record SubmitApplicationRequest(UUID jobOfferId) {}
