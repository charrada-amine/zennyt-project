package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ResumeAudience;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "soft_skills_summary", schema = "recruitment")
@IdClass(SoftSkillsSummaryEntity.Key.class)
public class SoftSkillsSummaryEntity {
    @Id private UUID candidateId;
    @Id @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16) private ResumeAudience audience;
    @Column(nullable = false, columnDefinition = "TEXT") private String textFr;
    @Column(nullable = false, columnDefinition = "TEXT") private String textEn;
    @Column(nullable = false) private Instant updatedAt;

    protected SoftSkillsSummaryEntity() {}
    SoftSkillsSummaryEntity(UUID candidateId, ResumeAudience audience,
                            String textFr, String textEn, Instant updatedAt) {
        this.candidateId = candidateId;
        this.audience = audience;
        this.textFr = textFr;
        this.textEn = textEn;
        this.updatedAt = updatedAt;
    }

    public UUID getCandidateId() { return candidateId; }
    public ResumeAudience getAudience() { return audience; }
    public String getTextFr() { return textFr; }
    public String getTextEn() { return textEn; }
    public Instant getUpdatedAt() { return updatedAt; }

    /**
     * Clé composite (candidat, public) — V58. Classe plutôt que record : {@code @IdClass}
     * exige un constructeur sans argument, qu'un record ne peut pas offrir.
     */
    public static class Key implements Serializable {
        private UUID candidateId;
        private ResumeAudience audience;

        public Key() {}
        public Key(UUID candidateId, ResumeAudience audience) {
            this.candidateId = candidateId;
            this.audience = audience;
        }

        @Override public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(candidateId, key.candidateId) && audience == key.audience;
        }

        @Override public int hashCode() { return Objects.hash(candidateId, audience); }
    }
}
