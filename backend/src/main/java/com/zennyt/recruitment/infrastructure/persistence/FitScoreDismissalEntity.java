package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@IdClass(FitScoreDismissalId.class)
@Table(name = "fit_score_dismissals", schema = "recruitment")
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
