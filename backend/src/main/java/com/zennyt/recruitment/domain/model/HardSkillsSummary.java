package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé IA des hard skills d'un candidat pour une offre donnée — combine son
 * CV et le résultat de sa tentative au test technique de cette offre. N'existe
 * que si le candidat a effectivement tenté le test (voir le fallback statique
 * géré au niveau de la lecture, pas ici).
 */
public record HardSkillsSummary(UUID id, UUID candidateId, UUID jobOfferId,
                                String textFr, String textEn, Instant updatedAt) {

    public static HardSkillsSummary create(UUID candidateId, UUID jobOfferId,
                                           String textFr, String textEn, Instant updatedAt) {
        return new HardSkillsSummary(UUID.randomUUID(), candidateId, jobOfferId, textFr, textEn, updatedAt);
    }
}
