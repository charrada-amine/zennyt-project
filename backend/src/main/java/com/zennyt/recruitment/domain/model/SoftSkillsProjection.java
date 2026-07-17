package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/** Projection locale du dernier score soft-skills publié par Games. */
public record SoftSkillsProjection(UUID candidateId, int score, Instant updatedAt) {
    public SoftSkillsProjection {
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException("Le score soft skills doit être entre 0 et 100");
        }
    }
}
