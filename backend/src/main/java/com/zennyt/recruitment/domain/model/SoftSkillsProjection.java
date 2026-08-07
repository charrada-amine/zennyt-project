package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Projection locale du dernier score soft-skills publié par Games, par module
 * (un module = un {@code GameType} côté Games, référencé ici uniquement par
 * son nom pour ne pas dépendre de {@code games.domain.vo.GameType}).
 *
 * <p>Une ligne par (candidat, module) — jouer MOVE_FAST puis PLANIFIK conserve
 * les deux scores au lieu d'écraser l'un par l'autre.
 */
public record SoftSkillsProjection(UUID id, UUID candidateId, String module, int score,
                                   int coverageRatio, Instant updatedAt) {
    public SoftSkillsProjection {
        if (module == null || module.isBlank()) {
            throw new IllegalArgumentException("Le module est obligatoire");
        }
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException("Le score soft skills doit être entre 0 et 100");
        }
        if (coverageRatio < 0 || coverageRatio > 100) {
            throw new IllegalArgumentException("Le taux de couverture doit être entre 0 et 100");
        }
    }

    public static SoftSkillsProjection create(UUID candidateId, String module, int score,
                                             int coverageRatio, Instant updatedAt) {
        return new SoftSkillsProjection(UUID.randomUUID(), candidateId, module, score,
            coverageRatio, updatedAt);
    }
}
