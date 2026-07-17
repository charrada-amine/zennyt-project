package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.List;
import java.util.UUID;

public interface JpaFitScoreRepository extends JpaRepository<FitScoreEntity, UUID> {

    /** Le score le plus récent pour la paire — tolère d'éventuels doublons historiques. */
    Optional<FitScoreEntity> findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(
        UUID candidateId, UUID jobOfferId);

    @Modifying
    @Transactional
    @Query(value = """
        INSERT INTO recruitment.fit_scores
            (id, candidate_id, job_offer_id, score, soft_skill_score, cv_match_score, computed_at)
        VALUES (:id, :candidateId, :jobOfferId, :score, :softSkillScore, :cvMatchScore, :computedAt)
        ON CONFLICT (candidate_id, job_offer_id) DO UPDATE SET
            score = EXCLUDED.score,
            soft_skill_score = EXCLUDED.soft_skill_score,
            cv_match_score = EXCLUDED.cv_match_score,
            computed_at = EXCLUDED.computed_at
        WHERE recruitment.fit_scores.computed_at <= EXCLUDED.computed_at
        """, nativeQuery = true)
    void upsert(UUID id, UUID candidateId, UUID jobOfferId, int score,
                Integer softSkillScore, Integer cvMatchScore, Instant computedAt);

    List<FitScoreEntity> findByJobOfferIdOrderByScoreDesc(UUID jobOfferId);

    List<FitScoreEntity> findByCandidateIdAndJobOfferIdIn(UUID candidateId, List<UUID> jobOfferIds);
}
