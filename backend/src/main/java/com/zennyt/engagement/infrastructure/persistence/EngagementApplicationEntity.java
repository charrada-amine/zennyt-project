package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "application_projections", schema = "engagement")
class EngagementApplicationEntity {
    @Id private UUID applicationId;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID recruiterId;
    private String jobTitle;
    @Column(nullable = false) private UUID lastEventId;
    @Column(nullable = false) private Instant lastEventAt;

    protected EngagementApplicationEntity() {}

    EngagementApplicationEntity(UUID applicationId, UUID jobOfferId, UUID candidateId,
                                UUID recruiterId, String jobTitle, UUID lastEventId, Instant lastEventAt) {
        this.applicationId = applicationId;
        update(jobOfferId, candidateId, recruiterId, jobTitle, lastEventId, lastEventAt);
    }

    void update(UUID jobOfferId, UUID candidateId, UUID recruiterId,
                String jobTitle, UUID lastEventId, Instant lastEventAt) {
        this.jobOfferId = jobOfferId;
        this.candidateId = candidateId;
        this.recruiterId = recruiterId;
        this.jobTitle = jobTitle;
        this.lastEventId = lastEventId;
        this.lastEventAt = lastEventAt;
    }

    UUID getApplicationId() { return applicationId; }
    UUID getJobOfferId() { return jobOfferId; }
    UUID getCandidateId() { return candidateId; }
    UUID getRecruiterId() { return recruiterId; }
    String getJobTitle() { return jobTitle; }
    UUID getLastEventId() { return lastEventId; }
    Instant getLastEventAt() { return lastEventAt; }
}
