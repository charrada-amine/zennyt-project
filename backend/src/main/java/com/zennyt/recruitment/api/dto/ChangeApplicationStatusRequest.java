package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;

/**
 * DTO pour changer le statut d'une candidature.
 *
 * <p>Distinct de {@link ChangeStatusRequest} (qui porte un {@code JobOfferStatus}) :
 * une candidature suit la machine à états PENDING → SHORTLISTED → APPROVED / REJECTED.
 */
public record ChangeApplicationStatusRequest(ApplicationStatus status) {}
