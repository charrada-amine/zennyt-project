package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.JobOfferStatus;

/** DTO pour changer le statut d'une offre. */
public record ChangeStatusRequest(JobOfferStatus status) {}
