package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.FitScorePolicy;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;

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
    private final Integer hardSkillScore;
    private final int coverageRatio;
    private final Instant computedAt;

    private FitScore(UUID id, UUID candidateId, UUID jobOfferId, int score,
                     Integer softSkillScore, Integer hardSkillScore,
                     int coverageRatio, Instant computedAt) {
        validateScore(score, "Le score");
        if (softSkillScore != null) validateScore(softSkillScore, "Le sous-score soft skills");
        if (hardSkillScore != null) validateScore(hardSkillScore, "Le sous-score hard skills");
        validateScore(coverageRatio, "Le taux de couverture");
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.score = score;
        this.softSkillScore = softSkillScore;
        this.hardSkillScore = hardSkillScore;
        this.coverageRatio = coverageRatio;
        this.computedAt = computedAt;
    }

    /** Créé à partir d'un callback IA externe — pas de détail par sous-score, couverture pleine par défaut. */
    public static FitScore fromCallback(UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        return new FitScore(UUID.randomUUID(), candidateId, jobOfferId, score,
            null, null, 100, computedAt != null ? computedAt : Instant.now());
    }

    /** Résultat du calculateur local, en conservant l'id lors d'un upsert. */
    public static FitScore calculated(UUID existingId, UUID candidateId, UUID jobOfferId,
                                      int score, int softSkillScore,
                                      Integer hardSkillScore, int coverageRatio, Instant computedAt) {
        return new FitScore(existingId != null ? existingId : UUID.randomUUID(), candidateId,
            jobOfferId, score, softSkillScore, hardSkillScore, coverageRatio,
            computedAt != null ? computedAt : Instant.now());
    }

    /** Reconstruction depuis la persistance. */
    public static FitScore rehydrate(UUID id, UUID candidateId, UUID jobOfferId, int score,
                                     Integer softSkillScore, Integer hardSkillScore,
                                     int coverageRatio, Instant computedAt) {
        return new FitScore(id, candidateId, jobOfferId, score, softSkillScore,
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
    public Integer hardSkillScore() { return hardSkillScore; }
    public int coverageRatio() { return coverageRatio; }

    /**
     * Données jugées incomplètes (CdC Fit Score v3 §3.3, mécanisme 2) —
     * n'ajuste pas le score, déclenche seulement une décision d'affichage
     * (badge côté client). Seuil renforcé à 70 % sans QCM hard skills (pas de
     * dimension hard pour compenser l'incertitude), 60 % avec QCM.
     *
     * <p><b>Correctif F04 (2026-08-04)</b> — le seuil se choisissait auparavant
     * sur {@code hardSkillScore != null}, c'est-à-dire « <i>ce candidat</i> a
     * terminé le test ». Le CdC §3.3 distingue pourtant « offre <b>avec</b> QCM »
     * de « offre <b>sans</b> QCM » : un candidat qui n'a pas encore passé un QCM
     * pourtant attaché à l'offre était jugé au seuil renforcé de 70 %, alors que
     * l'offre porte bien une dimension hard capable de compenser l'incertitude.
     *
     * <p><b>Le mode d'évaluation du métier (F32) entre ici.</b> Un métier en
     * {@link TypeEvaluationHard#MIXTE} attend <b>deux</b> mesures techniques — un QCM
     * <i>et</i> un portfolio (CdC §4.3) — et le portfolio n'a aucune note dans le
     * système : il n'existe que comme une URL sur le profil du candidat, qu'aucun
     * mécanisme n'évalue. Le sous-score hard d'un tel métier ne couvre donc, par
     * construction, que la moitié de ce que le métier exige.
     *
     * <p>Le <i>score</i> lui-même reste juste : conformément au principe posé en §2.2, on
     * retire le terme non mesurable au lieu de le mettre à zéro — un candidat n'est pas
     * puni pour une donnée que personne ne produit. Ce qui manquait était le
     * <b>signal</b> : rien ne disait au recruteur que la mesure était partielle et qu'il
     * lui restait un portfolio à regarder. Un métier Mixte est donc toujours signalé
     * comme partiel, quelle que soit la couverture soft.
     *
     * @param offerHasAssessment {@code true} si l'offre porte un QCM
     *                           ({@code JobOffer.assessmentId() != null}) —
     *                           propriété de l'offre, jamais de la tentative
     * @param evaluationMode     mode d'évaluation du MÉTIER de l'offre ; {@code null}
     *                           quand l'offre n'est pas encore reliée au référentiel,
     *                           auquel cas seule la couverture décide
     */
    public boolean partialData(boolean offerHasAssessment, TypeEvaluationHard evaluationMode) {
        if (evaluationMode == TypeEvaluationHard.MIXTE) return true;
        int threshold = offerHasAssessment
            ? FitScorePolicy.COVERAGE_THRESHOLD_WITH_HARD_SKILLS
            : FitScorePolicy.COVERAGE_THRESHOLD_SOFT_ONLY;
        return coverageRatio < threshold;
    }

    public Instant computedAt() { return computedAt; }
}
