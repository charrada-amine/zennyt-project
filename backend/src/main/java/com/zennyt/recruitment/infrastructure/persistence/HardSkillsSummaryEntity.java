package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ResumeAudience;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hard_skills_summary", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(columnNames = {"candidate_id", "job_position_id", "audience"}))
public class HardSkillsSummaryEntity {
    @Id private UUID id;
    @Column(name = "candidate_id", nullable = false) private UUID candidateId;
    @Column(name = "job_position_id", nullable = false) private UUID jobPositionId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16) private ResumeAudience audience;
    @Column(nullable = false, columnDefinition = "TEXT") private String textFr;
    @Column(nullable = false, columnDefinition = "TEXT") private String textEn;
    @Column(nullable = false) private Instant updatedAt;

    protected HardSkillsSummaryEntity() {}
    HardSkillsSummaryEntity(UUID id, UUID candidateId, UUID jobPositionId, ResumeAudience audience,
                            String textFr, String textEn, Instant updatedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobPositionId = jobPositionId;
        this.audience = audience;
        this.textFr = textFr;
        this.textEn = textEn;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobPositionId() { return jobPositionId; }
    public ResumeAudience getAudience() { return audience; }
    public String getTextFr() { return textFr; }
    public String getTextEn() { return textEn; }
    public Instant getUpdatedAt() { return updatedAt; }
}
