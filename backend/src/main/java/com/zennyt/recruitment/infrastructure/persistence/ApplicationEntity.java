package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/** Entité JPA pour la table applications. */
@Entity
@Table(name = "applications", schema = "recruitment")
public class ApplicationEntity {

    @Id

    private UUID id;

    @Column(nullable = false)
    private UUID candidateId;

    @Column(nullable = false)
    private UUID jobOfferId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ApplicationStatus status;

    @Column(nullable = false)
    private Instant appliedAt;

    private Instant updatedAt;

    protected ApplicationEntity() {}

    public ApplicationEntity(UUID id, UUID candidateId, UUID jobOfferId,
                              ApplicationStatus status, Instant appliedAt, Instant updatedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.status = status;
        this.appliedAt = appliedAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public ApplicationStatus getStatus() { return status; }
    public void setStatus(ApplicationStatus status) { this.status = status; }
    public Instant getAppliedAt() { return appliedAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
