package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hard_skills_summary", schema = "recruitment",
    uniqueConstraints = @UniqueConstraint(columnNames = {"candidate_id", "job_offer_id"}))
public class HardSkillsSummaryEntity {
    @Id private UUID id;
    @Column(name = "candidate_id", nullable = false) private UUID candidateId;
    @Column(name = "job_offer_id", nullable = false) private UUID jobOfferId;
    @Column(nullable = false, columnDefinition = "TEXT") private String textFr;
    @Column(nullable = false, columnDefinition = "TEXT") private String textEn;
    @Column(nullable = false) private Instant updatedAt;

    protected HardSkillsSummaryEntity() {}
    HardSkillsSummaryEntity(UUID id, UUID candidateId, UUID jobOfferId,
                            String textFr, String textEn, Instant updatedAt) {
        this.id = id;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.textFr = textFr;
        this.textEn = textEn;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public String getTextFr() { return textFr; }
    public String getTextEn() { return textEn; }
    public Instant getUpdatedAt() { return updatedAt; }
}
