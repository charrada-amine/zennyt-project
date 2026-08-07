package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "soft_skills_projection", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(columnNames = {"candidate_id", "module"}))
public class SoftSkillsProjectionEntity {
    @Id private UUID id;
    @Column(name = "candidate_id", nullable = false) private UUID candidateId;
    @Column(nullable = false) private String module;
    @Column(nullable = false) private int score;
    /** F13/F15 — couverture du module (0-100, CdC §3.3 mécanisme 1). */
    @Column(name = "coverage_ratio", nullable = false) private int coverageRatio;
    @Column(nullable = false) private Instant updatedAt;

    protected SoftSkillsProjectionEntity() {}
    SoftSkillsProjectionEntity(UUID id, UUID candidateId, String module, int score,
                              int coverageRatio, Instant updatedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.module = module;
        this.score = score;
        this.coverageRatio = coverageRatio;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public String getModule() { return module; }
    public int getScore() { return score; }
    public int getCoverageRatio() { return coverageRatio; }
    public Instant getUpdatedAt() { return updatedAt; }
}
