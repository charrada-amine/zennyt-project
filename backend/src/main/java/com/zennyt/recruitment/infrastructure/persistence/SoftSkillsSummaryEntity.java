package com.zennyt.recruitment.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "soft_skills_summary", schema = "recruitment")
public class SoftSkillsSummaryEntity {
    @Id private UUID candidateId;
    @Column(nullable = false, columnDefinition = "TEXT") private String textFr;
    @Column(nullable = false, columnDefinition = "TEXT") private String textEn;
    @Column(nullable = false) private Instant updatedAt;

    protected SoftSkillsSummaryEntity() {}
    SoftSkillsSummaryEntity(UUID candidateId, String textFr, String textEn, Instant updatedAt) {
        this.candidateId = candidateId;
        this.textFr = textFr;
        this.textEn = textEn;
        this.updatedAt = updatedAt;
    }

    public UUID getCandidateId() { return candidateId; }
    public String getTextFr() { return textFr; }
    public String getTextEn() { return textEn; }
    public Instant getUpdatedAt() { return updatedAt; }
}
