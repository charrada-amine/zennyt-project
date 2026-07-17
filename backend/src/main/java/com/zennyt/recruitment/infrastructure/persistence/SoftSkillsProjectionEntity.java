package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "soft_skills_projection", schema = "recruitment")
public class SoftSkillsProjectionEntity {
    @Id private UUID candidateId;
    @Column(nullable = false) private int score;
    @Column(nullable = false) private Instant updatedAt;

    protected SoftSkillsProjectionEntity() {}
    SoftSkillsProjectionEntity(UUID candidateId, int score, Instant updatedAt) {
        this.candidateId = candidateId;
        this.score = score;
        this.updatedAt = updatedAt;
    }

    public UUID getCandidateId() { return candidateId; }
    public int getScore() { return score; }
    public Instant getUpdatedAt() { return updatedAt; }
}
