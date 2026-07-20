package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.*;
import org.openapitools.jackson.nullable.JsonNullable;

import java.util.UUID;

/**
 * DTO de requête pour la mise à jour partielle d'une offre (PATCH).
 *
 * <p>Tout champ absent du JSON est laissé inchangé. {@code assessmentId}
 * utilise {@link JsonNullable} pour distinguer « absent » (inchangé) de
 * « null » explicite (désassigner l'évaluation). {@code recruiterId},
 * {@code id} et {@code postedAt} ne sont jamais modifiables.
 */
public record UpdateJobOfferRequest(
    String title, String companyName,
    String city, String country, Boolean remote,
    Double salaryMin, Double salaryMax, String currency,
    ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
    String fieldOfWork, String description, String responsibilities,
    String minimumQualifications, String preferredQualifications,
    String whatWeOffer, String howToApply, String companyInfo,
    JsonNullable<UUID> assessmentId, UUID jobPositionId, Integer passingScore, Boolean openToInternational,
    JobOfferStatus status
) {
    public UpdateJobOfferRequest {
        if (assessmentId == null) assessmentId = JsonNullable.undefined();
    }
}
