package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Projection locale du CV du candidat (via {@code identity.ProfileCvUpdatedEvent}),
 * pré-formatée en texte pour alimenter le résumé IA — pas de structure exposée
 * ailleurs, ce n'est pas un modèle de lecture public.
 */
public record CvProfileProjection(UUID candidateId, String cvText, Instant updatedAt) {
    public CvProfileProjection {
        if (cvText == null) cvText = "";
    }
}
