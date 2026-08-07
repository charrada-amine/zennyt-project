package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé IA des soft skills d'un candidat, à partir de ses scores par module
 * psychométrique. Candidat-level : réutilisé tel quel pour toutes les offres, puisque les
 * résultats psychométriques ne dépendent pas de l'offre consultée.
 *
 * <p>Une ligne par public visé (P5) — même fond, formulation adaptée.
 */
public record SoftSkillsSummary(UUID candidateId, ResumeAudience audience,
                                String textFr, String textEn, Instant updatedAt) {
}
