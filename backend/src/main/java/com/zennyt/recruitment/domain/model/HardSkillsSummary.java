package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ResumeAudience;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé IA des hard skills d'un candidat sur un <b>métier</b> — combine son CV et
 * l'historique de ses tests techniques sur ce métier.
 *
 * <p>Était auparavant rattaché à une offre. Depuis D1, le sous-score hard s'estime sur tout
 * l'historique du candidat sur le métier : garder un résumé par offre aurait produit N
 * textes identiques pour N offres du même métier, chacun régénéré et facturé séparément.
 *
 * <p>N'existe que si le candidat a effectivement passé un test sur ce métier (voir le repli
 * statique géré au niveau de la lecture, pas ici).
 */
public record HardSkillsSummary(UUID id, UUID candidateId, UUID jobPositionId,
                                ResumeAudience audience,
                                String textFr, String textEn, Instant updatedAt) {

    public static HardSkillsSummary create(UUID candidateId, UUID jobPositionId,
                                           ResumeAudience audience,
                                           String textFr, String textEn, Instant updatedAt) {
        return new HardSkillsSummary(UUID.randomUUID(), candidateId, jobPositionId, audience,
            textFr, textEn, updatedAt);
    }
}
