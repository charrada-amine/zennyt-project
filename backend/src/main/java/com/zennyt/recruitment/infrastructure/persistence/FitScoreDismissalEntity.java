package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import jakarta.persistence.Index;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@IdClass(FitScoreDismissalId.class)
@Table(name = "fit_score_dismissals", schema = "recruitment",
    // Ordre des colonnes de la clé primaire, fusionné dans fit_score_dismissals_pkey.
    uniqueConstraints = @UniqueConstraint(name = "fit_score_dismissals_pkey", columnNames = {"recruiter_id", "candidate_id", "job_offer_id"}),
    indexes = @Index(name = "idx_fit_score_dismissals_offer", columnList = "job_offer_id"))
public class FitScoreDismissalEntity {
    @Id private UUID recruiterId;
    @Id private UUID candidateId;
    @Id private UUID jobOfferId;
    @Column(nullable = false) private Instant dismissedAt;

    protected FitScoreDismissalEntity() {}
    FitScoreDismissalEntity(UUID recruiterId, UUID candidateId, UUID jobOfferId, Instant dismissedAt) {
        this.recruiterId = recruiterId;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.dismissedAt = dismissedAt;
    }
}
