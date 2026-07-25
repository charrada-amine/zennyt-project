package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.TestResultStatus;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "test_results", schema = "recruitment")
public class TestResultEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID hardSkillTestId;
    @Column(nullable = false) private UUID candidateId;
    private int score;
    private int percentage;
    private boolean passed;
    @Column(columnDefinition = "TEXT") private String answersJson;
    @Column(nullable = false) private Instant startedAt;
    @Column(nullable = false) private Instant completedAt;
    private int duration;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private TestResultStatus status;

    protected TestResultEntity() {}

    public TestResultEntity(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                            int score, int percentage, boolean passed, String answersJson,
                            Instant startedAt, Instant completedAt, int duration, TestResultStatus status) {
        this.id = id;
        this.jobOfferId = jobOfferId;
        this.hardSkillTestId = hardSkillTestId;
        this.candidateId = candidateId;
        this.score = score;
        this.percentage = percentage;
        this.passed = passed;
        this.answersJson = answersJson;
        this.startedAt = startedAt;
        this.completedAt = completedAt;
        this.duration = duration;
        this.status = status;
    }

    public UUID getId() { return id; }
    public UUID getJobOfferId() { return jobOfferId; }
    public UUID getHardSkillTestId() { return hardSkillTestId; }
    public UUID getCandidateId() { return candidateId; }
    public int getScore() { return score; }
    public int getPercentage() { return percentage; }
    public boolean isPassed() { return passed; }
    public String getAnswersJson() { return answersJson; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public int getDuration() { return duration; }
    public TestResultStatus getStatus() { return status; }
}
