package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Score de compatibilité IA entre un candidat et une offre (0-100).
 *
 * <p>Calculé de manière asynchrone par un service IA externe qui poste
 * le résultat via le callback {@code POST /callbacks/fit-score}.
 */
public class FitScore {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final int score;
    private final Instant computedAt;

    private FitScore(UUID id, UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException("Le score doit être entre 0 et 100");
        }
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.score = score;
        this.computedAt = computedAt;
    }

    /** Créé à partir d'un callback IA. */
    public static FitScore fromCallback(UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        return new FitScore(UUID.randomUUID(), candidateId, jobOfferId, score,
            computedAt != null ? computedAt : Instant.now());
    }

    /** Reconstruction depuis la persistance. */
    public static FitScore rehydrate(UUID id, UUID candidateId, UUID jobOfferId, int score, Instant computedAt) {
        return new FitScore(id, candidateId, jobOfferId, score, computedAt);
    }

    public UUID id() { return id; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public int score() { return score; }
    public Instant computedAt() { return computedAt; }
}
