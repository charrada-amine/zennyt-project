package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cv_profile_projection", schema = "recruitment")
public class CvProfileProjectionEntity {
    @Id private UUID candidateId;
    @Column(nullable = false, columnDefinition = "TEXT") private String cvText;
    @Column(nullable = false) private Instant updatedAt;

    protected CvProfileProjectionEntity() {}
    CvProfileProjectionEntity(UUID candidateId, String cvText, Instant updatedAt) {
        this.candidateId = candidateId;
        this.cvText = cvText;
        this.updatedAt = updatedAt;
    }

    public UUID getCandidateId() { return candidateId; }
    public String getCvText() { return cvText; }
    public Instant getUpdatedAt() { return updatedAt; }
}
