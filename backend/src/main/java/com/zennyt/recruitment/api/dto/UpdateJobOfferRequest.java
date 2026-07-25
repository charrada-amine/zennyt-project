package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.*;
import org.openapitools.jackson.nullable.JsonNullable;

import java.util.UUID;

/**
 * DTO de requête pour la mise à jour partielle d'une offre (PATCH).
 *
 * <p>Contrat squad web §3.3 : seuls {@code status} et {@code assessmentId}
 * sont modifiables par ce endpoint — tout autre champ passe par PUT. Un champ
 * JSON inconnu déclenche un 400 (désérialisation Jackson stricte par défaut).
 * {@code assessmentId} utilise {@link JsonNullable} pour distinguer « absent »
 * (inchangé) de « null » explicite (désassigner l'évaluation).
 */
public record UpdateJobOfferRequest(
    JsonNullable<UUID> assessmentId, JobOfferStatus status
) {
    public UpdateJobOfferRequest {
        if (assessmentId == null) assessmentId = JsonNullable.undefined();
    }
}
