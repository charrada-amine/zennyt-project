package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "assessment_attempts", schema = "recruitment")
public class AssessmentAttemptEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID assessmentId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID jobOfferId;
    private UUID applicationId;
    private int score;
    private boolean passed;
    private boolean monitoringConsent;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private IntegrityStatus integrityStatus;
    @Column(nullable = false) private Instant submittedAt;

    protected AssessmentAttemptEntity() {}
    public AssessmentAttemptEntity(UUID id, UUID assessmentId, UUID candidateId, UUID jobOfferId, UUID applicationId,
                                   int score, boolean passed, boolean monitoringConsent,
                                   IntegrityStatus integrityStatus, Instant submittedAt) {
        this.id = id; this.assessmentId = assessmentId; this.candidateId = candidateId;
        this.jobOfferId = jobOfferId; this.applicationId = applicationId; this.score = score; this.passed = passed;
        this.monitoringConsent = monitoringConsent;
        this.integrityStatus = integrityStatus; this.submittedAt = submittedAt;
    }

    public UUID getId() { return id; }
    public UUID getAssessmentId() { return assessmentId; }
    public UUID getCandidateId() { return candidateId; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getApplicationId() { return applicationId; }
    public int getScore() { return score; }
    public boolean isPassed() { return passed; }
    public boolean isMonitoringConsent() { return monitoringConsent; }
    public IntegrityStatus getIntegrityStatus() { return integrityStatus; }
    public void setIntegrityStatus(IntegrityStatus v) { this.integrityStatus = v; }
    public Instant getSubmittedAt() { return submittedAt; }
}
