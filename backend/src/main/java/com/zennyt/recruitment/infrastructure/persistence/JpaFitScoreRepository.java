package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

public interface JpaFitScoreRepository extends JpaRepository<FitScoreEntity, UUID> {

    /** Le score le plus récent pour la paire — tolère d'éventuels doublons historiques. */
    Optional<FitScoreEntity> findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(
        UUID candidateId, UUID jobOfferId);

    /** Supprime tout score existant pour la paire (utilisé pour un upsert). */
    @Transactional
    void deleteByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
}
