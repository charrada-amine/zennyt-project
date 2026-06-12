package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Entité JPA de persistance — volontairement distincte de l'agrégat {@code Application}.
 *
 * <p>On ne mappe pas JPA directement sur l'agrégat : cela polluerait le domaine
 * d'annotations d'infrastructure. L'adaptateur repository convertit entre les
 * deux mondes (mapper). Le domaine reste pur.
 */
@Entity
@Table(
    name = "applications",
    schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(columnNames = {"candidate_id", "job_id"})
)
public class ApplicationEntity {

    @Id
    private UUID id;

    @Column(name = "candidate_id", nullable = false)
    private UUID candidateId;

    @Column(name = "job_id", nullable = false)
    private UUID jobId;

    @Column(name = "cover_letter", length = 4000)
    private String coverLetter;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ApplicationStatus status;

    @Column(name = "applied_at", nullable = false)
    private Instant appliedAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ApplicationEntity() { } // requis par JPA

    public ApplicationEntity(UUID id, UUID candidateId, UUID jobId, String coverLetter,
                             ApplicationStatus status, Instant appliedAt, Instant updatedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobId = jobId;
        this.coverLetter = coverLetter;
        this.status = status;
        this.appliedAt = appliedAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobId() { return jobId; }
    public String getCoverLetter() { return coverLetter; }
    public ApplicationStatus getStatus() { return status; }
    public Instant getAppliedAt() { return appliedAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
