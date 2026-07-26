package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.FitScorePolicy;

import java.time.Instant;
import java.util.UUID;

/**
 * Score de compatibilité entre un candidat et une offre (0-100).
 *
 * <p>Calculé par le moteur local derrière un port interchangeable
 * (déterministe — CdC Fit Score v3 — ou IA), ou écrit par le callback externe.
 */
public class FitScore {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final int score;
    private final Integer softSkillScore;
    private final Integer cvMatchScore;
    private final Integer hardSkillScore;
    private final int coverageRatio;
    private final Instant computedAt;

    private FitScore(UUID id, UUID candidateId, UUID jobOfferId, int score,
                     Integer softSkillScore, Integer cvMatchScore, Integer hardSkillScore,
                     int coverageRatio, Instant computedAt) {
        validateScore(score, "Le score");
        if (softSkillScore != null) validateScore(softSkillScore, "Le sous-score soft skills");
        if (cvMatchScore != null) validateScore(cvMatchScore, "Le sous-score CV");
        if (hardSkillScore != null) validateScore(hardSkillScore, "Le sous-score hard skills");
        validateScore(coverageRatio, "Le taux de couverture");
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.score = score;
        this.softSkillScore = softSkillScore;
        this.cvMatchScore = cvMatchScore;
        this.hardSkillScore = hardSkillScore;
        this.coverageRatio = coverageRatio;
        this.computedAt = computedAt;
    }

    /** Créé à partir d'un callback IA externe — pas de détail par sous-score, couverture pleine par défaut. */
    public static FitScore fromCallback(UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        return new FitScore(UUID.randomUUID(), candidateId, jobOfferId, score,
            null, null, null, 100, computedAt != null ? computedAt : Instant.now());
    }

    /** Résultat du calculateur local, en conservant l'id lors d'un upsert. */
    public static FitScore calculated(UUID existingId, UUID candidateId, UUID jobOfferId,
                                      int score, int softSkillScore, int cvMatchScore,
                                      Integer hardSkillScore, int coverageRatio, Instant computedAt) {
        return new FitScore(existingId != null ? existingId : UUID.randomUUID(), candidateId,
            jobOfferId, score, softSkillScore, cvMatchScore, hardSkillScore, coverageRatio,
            computedAt != null ? computedAt : Instant.now());
    }

    /** Reconstruction depuis la persistance. */
    public static FitScore rehydrate(UUID id, UUID candidateId, UUID jobOfferId, int score,
                                     Integer softSkillScore, Integer cvMatchScore, Integer hardSkillScore,
                                     int coverageRatio, Instant computedAt) {
        return new FitScore(id, candidateId, jobOfferId, score, softSkillScore, cvMatchScore,
            hardSkillScore, coverageRatio, computedAt);
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
    public Integer hardSkillScore() { return hardSkillScore; }
    public int coverageRatio() { return coverageRatio; }

    /**
     * Données jugées incomplètes (CdC Fit Score v3 §3.3, mécanisme 2) —
     * n'ajuste pas le score, déclenche seulement une décision d'affichage
     * (badge côté client). Seuil renforcé à 70 % sans QCM hard skills (pas de
     * dimension hard pour compenser l'incertitude), 60 % avec QCM.
     */
    public boolean partialData() {
        int threshold = hardSkillScore != null
            ? FitScorePolicy.COVERAGE_THRESHOLD_WITH_HARD_SKILLS
            : FitScorePolicy.COVERAGE_THRESHOLD_SOFT_ONLY;
        return coverageRatio < threshold;
    }

    public Instant computedAt() { return computedAt; }
}
