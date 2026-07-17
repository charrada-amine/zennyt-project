package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.FitScorePolicy;

import java.time.Instant;
import java.util.UUID;

/**
 * Score de compatibilité IA entre un candidat et une offre (0-100).
 *
 * <p>Calculé par le moteur local derrière un port IA, ou écrit par le callback externe.
 */
public class FitScore {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final int score;
    private final Integer softSkillScore;
    private final Integer cvMatchScore;
    private final Instant computedAt;

    private FitScore(UUID id, UUID candidateId, UUID jobOfferId, int score,
                     Integer softSkillScore, Integer cvMatchScore, Instant computedAt) {
        validateScore(score, "Le score");
        if (softSkillScore != null) validateScore(softSkillScore, "Le sous-score soft skills");
        if (cvMatchScore != null) validateScore(cvMatchScore, "Le sous-score CV");
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.score = score;
        this.softSkillScore = softSkillScore;
        this.cvMatchScore = cvMatchScore;
        this.computedAt = computedAt;
    }

    /** Créé à partir d'un callback IA. */
    public static FitScore fromCallback(UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        return new FitScore(UUID.randomUUID(), candidateId, jobOfferId, score,
            null, null, computedAt != null ? computedAt : Instant.now());
    }

    /** Résultat du calculateur local, en conservant l'id lors d'un upsert. */
    public static FitScore calculated(UUID existingId, UUID candidateId, UUID jobOfferId,
                                      int score, int softSkillScore, int cvMatchScore,
                                      Instant computedAt) {
        return new FitScore(existingId != null ? existingId : UUID.randomUUID(), candidateId,
            jobOfferId, score, softSkillScore, cvMatchScore,
            computedAt != null ? computedAt : Instant.now());
    }

    /** Reconstruction depuis la persistance. */
    public static FitScore rehydrate(UUID id, UUID candidateId, UUID jobOfferId, int score,
                                     Integer softSkillScore, Integer cvMatchScore, Instant computedAt) {
        return new FitScore(id, candidateId, jobOfferId, score, softSkillScore, cvMatchScore, computedAt);
    }

    private static void validateScore(int score, String label) {
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException(label + " doit être entre 0 et 100");
        }
    }

    public UUID id() { return id; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public int score() { return score; }
    public boolean goodFit() { return score >= FitScorePolicy.GOOD_FIT_MIN_SCORE; }
    public Integer softSkillScore() { return softSkillScore; }
    public Integer cvMatchScore() { return cvMatchScore; }
    public Instant computedAt() { return computedAt; }
}
