package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "fit_scores", schema = "recruitment")
public class FitScoreEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private int score;
    private Integer softSkillScore;
    private Integer hardSkillScore;
    @Column(nullable = false) private int coverageRatio;
    @Column(nullable = false) private Instant computedAt;

    protected FitScoreEntity() {}
    public FitScoreEntity(UUID id, UUID candidateId, UUID jobOfferId, int score,
                          Integer softSkillScore, Integer hardSkillScore,
                          int coverageRatio, Instant computedAt) {
        this.id = id; this.candidateId = candidateId; this.jobOfferId = jobOfferId;
        this.score = score; this.softSkillScore = softSkillScore;
        this.hardSkillScore = hardSkillScore;
        this.coverageRatio = coverageRatio; this.computedAt = computedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public int getScore() { return score; }
    public Integer getSoftSkillScore() { return softSkillScore; }
    public Integer getHardSkillScore() { return hardSkillScore; }
    public int getCoverageRatio() { return coverageRatio; }
    public Instant getComputedAt() { return computedAt; }
}
