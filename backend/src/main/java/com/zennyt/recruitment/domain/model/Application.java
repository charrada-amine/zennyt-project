package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.UUID;

/**
 * Agrégat Candidature — racine d'agrégat du contexte Recruitment.
 *
 * <p>Toute la logique métier vit ici : la création enregistre un événement,
 * les transitions de statut valident la machine à états. L'agrégat est
 * indépendant de JPA, de Spring et du web — c'est du Java pur, testable
 * unitairement sans contexte.
 */
public class Application extends AggregateRoot {

    private final UUID id;
    private final UUID candidateId;
    private final UUID jobId;
    private String coverLetter;
    private ApplicationStatus status;
    private final Instant appliedAt;
    private Instant updatedAt;

    private Application(UUID id, UUID candidateId, UUID jobId, String coverLetter) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobId = jobId;
        this.coverLetter = coverLetter;
        this.status = ApplicationStatus.SUBMITTED;
        this.appliedAt = Instant.now();
        this.updatedAt = this.appliedAt;
    }

    /** Fabrique : crée une candidature et enregistre l'événement de soumission. */
    public static Application submit(UUID candidateId, UUID jobId, String coverLetter) {
        Application app = new Application(UUID.randomUUID(), candidateId, jobId, coverLetter);
        app.registerEvent(ApplicationSubmittedEvent.of(app.id, candidateId, jobId));
        return app;
    }

    /** Reconstruction depuis la persistance (pas d'événement émis). */
    public static Application rehydrate(UUID id, UUID candidateId, UUID jobId,
                                        String coverLetter, ApplicationStatus status,
                                        Instant appliedAt, Instant updatedAt) {
        Application app = new Application(id, candidateId, jobId, coverLetter);
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
    public UUID jobId() { return jobId; }
    public String coverLetter() { return coverLetter; }
    public ApplicationStatus status() { return status; }
    public Instant appliedAt() { return appliedAt; }
    public Instant updatedAt() { return updatedAt; }
}
