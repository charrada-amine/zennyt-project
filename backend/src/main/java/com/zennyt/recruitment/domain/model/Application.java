package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Candidature — soumission d'un candidat à une offre.
 *
 * <p>Machine à états : PENDING → SHORTLISTED → APPROVED / REJECTED.
 * Une seule candidature par couple (candidat, offre).
 */
public class Application extends AggregateRoot {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private ApplicationStatus status;
    private final Instant appliedAt;
    private Instant updatedAt;

    private Application(UUID id, UUID candidateId, UUID jobOfferId) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.status = ApplicationStatus.PENDING;
        this.appliedAt = Instant.now();
        this.updatedAt = this.appliedAt;
    }

    /** Fabrique métier. L'événement enrichi est publié par le cas d'usage qui connaît l'offre. */
    public static Application submit(UUID candidateId, UUID jobOfferId) {
        return new Application(UUID.randomUUID(), candidateId, jobOfferId);
    }

    /** Reconstruction depuis la persistance (pas d'événement émis). */
    public static Application rehydrate(UUID id, UUID candidateId, UUID jobOfferId,
                                        ApplicationStatus status,
                                        Instant appliedAt, Instant updatedAt) {
        Application app = new Application(id, candidateId, jobOfferId);
        app.status = status;
        app.updatedAt = updatedAt;
        return app;
    }

    /** Transition de statut : valide la machine à états du domaine. */
    public void changeStatus(ApplicationStatus target) {
        if (!this.status.canTransitionTo(target)) {
            throw new IllegalArgumentException(
                "Transition interdite : " + this.status + " -> " + target);
        }
        this.status = target;
        this.updatedAt = Instant.now();
    }

    public UUID id() { return id; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public ApplicationStatus status() { return status; }
    public Instant appliedAt() { return appliedAt; }
    public Instant updatedAt() { return updatedAt; }
}
