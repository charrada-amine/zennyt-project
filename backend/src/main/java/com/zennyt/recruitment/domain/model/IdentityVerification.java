package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.IdentityVerificationRequestedEvent;
import com.zennyt.recruitment.domain.vo.IdentityVerificationStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Vérification d'identité anti-fraude (reconnaissance faciale).
 *
 * <p>Demandée par le recruteur pour un candidat. Le résultat est posté
 * par un service tiers via {@code POST /callbacks/identity-verification}.
 */
public class IdentityVerification extends AggregateRoot {

    private final UUID id;
    private final UUID requestedByRecruiterId;
    private final UUID targetCandidateId;
    private final UUID jobOfferId; // contexte optionnel
    private IdentityVerificationStatus status;
    private final Instant requestedAt;
    private Instant resolvedAt;

    private IdentityVerification(UUID id, UUID requestedByRecruiterId, UUID targetCandidateId, UUID jobOfferId) {
        this.id = id;
        this.requestedByRecruiterId = requestedByRecruiterId;
        this.targetCandidateId = targetCandidateId;
        this.jobOfferId = jobOfferId;
        this.status = IdentityVerificationStatus.PENDING;
        this.requestedAt = Instant.now();
    }

    /** Fabrique : demander une vérification. */
    public static IdentityVerification request(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        IdentityVerification verification = new IdentityVerification(
            UUID.randomUUID(), recruiterId, candidateId, jobOfferId);
        verification.registerEvent(IdentityVerificationRequestedEvent.of(
            verification.id, recruiterId, candidateId));
        return verification;
    }

    /** Reconstruction depuis la persistance. */
    public static IdentityVerification rehydrate(UUID id, UUID requestedByRecruiterId,
                                                  UUID targetCandidateId, UUID jobOfferId,
                                                  IdentityVerificationStatus status,
                                                  Instant requestedAt, Instant resolvedAt) {
        IdentityVerification v = new IdentityVerification(id, requestedByRecruiterId, targetCandidateId, jobOfferId);
        v.status = status;
        v.resolvedAt = resolvedAt;
        return v;
    }

    /** Résolution par le callback tiers. */
    public void resolve(IdentityVerificationStatus result) {
        if (this.status != IdentityVerificationStatus.PENDING) {
            throw new IllegalStateException("La vérification a déjà été résolue");
        }
        this.status = result;
        this.resolvedAt = Instant.now();
    }

    public UUID id() { return id; }
    public UUID requestedByRecruiterId() { return requestedByRecruiterId; }
    public UUID targetCandidateId() { return targetCandidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public IdentityVerificationStatus status() { return status; }
    public Instant requestedAt() { return requestedAt; }
    public Instant resolvedAt() { return resolvedAt; }
}
