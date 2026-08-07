package com.zennyt.recruitment.domain.vo;

import java.util.UUID;

/**
 * Un couple (candidat, métier) — l'unité de lecture de l'historique hard skills.
 *
 * <p>Pendant de {@link CandidateOfferPair} pour les lectures qui ne dépendent plus de
 * l'offre mais du métier : depuis la décision D1, le sous-score hard d'un candidat est
 * estimé sur <b>tous</b> ses tests du même {@code jobPositionId}, pas sur le seul test
 * attaché à l'offre consultée. Même raison d'être que la paire : cibler exactement les
 * couples demandés plutôt que leur produit croisé.
 */
public record CandidateJobPositionCouple(UUID candidateId, UUID jobPositionId) {
    public CandidateJobPositionCouple {
        if (candidateId == null) throw new IllegalArgumentException("candidateId est obligatoire");
        if (jobPositionId == null) throw new IllegalArgumentException("jobPositionId est obligatoire");
    }
}
