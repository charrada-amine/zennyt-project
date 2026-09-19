package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.TestAttemptStatus;
import jakarta.persistence.*;
import org.hibernate.Length;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "test_attempts", schema = "recruitment",
    indexes = @Index(name = "idx_test_attempts_candidate_job", columnList = "candidate_id, job_offer_id"))
public class TestAttemptEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID hardSkillTestId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private Instant startedAt;
    @Column(nullable = false) private Instant expiresAt;
    @Column(length = Length.LONG32) private String presentedQuestionsJson;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private TestAttemptStatus status;

    protected TestAttemptEntity() {}

    public TestAttemptEntity(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                             Instant startedAt, Instant expiresAt, String presentedQuestionsJson,
                             TestAttemptStatus status) {
        this.id = id;
        this.jobOfferId = jobOfferId;
        this.hardSkillTestId = hardSkillTestId;
        this.candidateId = candidateId;
        this.startedAt = startedAt;
        this.expiresAt = expiresAt;
        this.presentedQuestionsJson = presentedQuestionsJson;
        this.status = status;
    }

    public UUID getId() { return id; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getHardSkillTestId() { return hardSkillTestId; }
    public UUID getCandidateId() { return candidateId; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getExpiresAt() { return expiresAt; }
    public String getPresentedQuestionsJson() { return presentedQuestionsJson; }
    public TestAttemptStatus getStatus() { return status; }
}
