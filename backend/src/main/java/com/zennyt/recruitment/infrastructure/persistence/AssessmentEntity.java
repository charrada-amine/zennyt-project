package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.AssessmentGenerationMode;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "assessments", schema = "recruitment")
public class AssessmentEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID createdByRecruiterId;
    @Column(nullable = false) private String title;
    private int timeLimitSeconds;
    private int maxQuestions;
    @Enumerated(EnumType.STRING) private AssessmentGenerationMode generationSource;
    private String shareableLink;
    @Column(columnDefinition = "TEXT") private String questionsJson;
    @Column(nullable = false) private Instant createdAt;

    protected AssessmentEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getCreatedByRecruiterId() { return createdByRecruiterId; }
    public void setCreatedByRecruiterId(UUID v) { this.createdByRecruiterId = v; }
    public String getTitle() { return title; }
    public void setTitle(String v) { this.title = v; }
    public int getTimeLimitSeconds() { return timeLimitSeconds; }
    public void setTimeLimitSeconds(int v) { this.timeLimitSeconds = v; }
    public int getMaxQuestions() { return maxQuestions; }
    public void setMaxQuestions(int v) { this.maxQuestions = v; }
    public AssessmentGenerationMode getGenerationSource() { return generationSource; }
    public void setGenerationSource(AssessmentGenerationMode v) { this.generationSource = v; }
    public String getShareableLink() { return shareableLink; }
    public void setShareableLink(String v) { this.shareableLink = v; }
    public String getQuestionsJson() { return questionsJson; }
    public void setQuestionsJson(String v) { this.questionsJson = v; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant v) { this.createdAt = v; }
}
