package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé IA des soft skills d'un candidat (basé sur les modules psychométriques
 * joués) — candidat-level, réutilisé pour toutes les offres. Bilingue : les
 * deux versions sont générées ensemble, "View original version" bascule entre
 * les deux sans appel supplémentaire.
 */
public record SoftSkillsSummary(UUID candidateId, String textFr, String textEn, Instant updatedAt) {
}
