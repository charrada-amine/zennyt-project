package com.zennyt.recruitment.domain.vo;

import java.util.UUID;

/**
 * Une paire (candidat, offre) — l'unité de travail du calcul de Fit Score.
 *
 * <p>Existe pour que les lectures par lot ciblent <b>exactement</b> les paires demandées.
 * Les signatures précédentes prenaient deux listes séparées ({@code candidateIds},
 * {@code jobOfferIds}) traduites en {@code WHERE candidate_id IN (...) AND job_offer_id
 * IN (...)} : cela remonte le <b>produit croisé</b> des deux listes, pas les paires.
 * Sur un lot de 200 paires réparties sur 50 candidats et 50 offres, 2 500 lignes étaient
 * lues pour en garder 200 — et la sur-lecture croît au carré de la taille du lot, ce qui
 * bornait de fait la taille de lot exploitable.
 */
public record CandidateOfferPair(UUID candidateId, UUID jobOfferId) {
    public CandidateOfferPair {
        if (candidateId == null) throw new IllegalArgumentException("candidateId est obligatoire");
        if (jobOfferId == null) throw new IllegalArgumentException("jobOfferId est obligatoire");
    }
}
