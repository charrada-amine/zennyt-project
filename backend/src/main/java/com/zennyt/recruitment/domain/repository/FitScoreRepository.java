package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.FitScore;

import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de scores de compatibilité.
 */
public interface FitScoreRepository {

    FitScore save(FitScore fitScore);

    /** Score entre un candidat et une offre (calculé par l'IA). */
    Optional<FitScore> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
}
