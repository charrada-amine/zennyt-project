package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "soft_skills_projection", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(name = "uq_soft_skills_projection_candidate_module", columnNames = {"candidate_id", "module"}))
@Check(name = "ck_soft_skills_projection_coverage", constraints = "coverage_ratio >= 0 AND coverage_ratio <= 100")
@Check(name = "ck_soft_skills_projection_score", constraints = "score >= 0 AND score <= 100")
public class SoftSkillsProjectionEntity {
    @Id private UUID id;
    @Column(name = "candidate_id", nullable = false) private UUID candidateId;
    @Column(nullable = false, length = 50) private String module;
    @Column(nullable = false) private int score;
    /** F13/F15 — couverture du module (0-100, CdC §3.3 mécanisme 1). */
    @ColumnDefault("100") @Column(name = "coverage_ratio", nullable = false) private int coverageRatio;
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
