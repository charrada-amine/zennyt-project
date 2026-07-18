package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "conversations", schema = "engagement")
class ConversationEntity {
    @Id private UUID id;
    @Column(nullable = false, unique = true) private UUID applicationId;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID recruiterId;
    private String jobTitle;
    @Column(nullable = false, length = 103) private String lastMessagePreview;
    private Instant lastMessageAt;
    @Column(nullable = false) private int candidateUnreadCount;
    @Column(nullable = false) private int recruiterUnreadCount;
    @Version private long version;

    protected ConversationEntity() {}

    ConversationEntity(UUID id, UUID applicationId, UUID jobOfferId, UUID candidateId,
                       UUID recruiterId, String jobTitle, String lastMessagePreview,
                       Instant lastMessageAt, int candidateUnreadCount, int recruiterUnreadCount) {
        this.id = id;
        update(applicationId, jobOfferId, candidateId, recruiterId, jobTitle,
            lastMessagePreview, lastMessageAt, candidateUnreadCount, recruiterUnreadCount);
    }

    void update(UUID applicationId, UUID jobOfferId, UUID candidateId, UUID recruiterId,
                String jobTitle, String lastMessagePreview, Instant lastMessageAt,
                int candidateUnreadCount, int recruiterUnreadCount) {
        this.applicationId = applicationId;
        this.jobOfferId = jobOfferId;
        this.candidateId = candidateId;
        this.recruiterId = recruiterId;
        this.jobTitle = jobTitle;
        this.lastMessagePreview = lastMessagePreview;
        this.lastMessageAt = lastMessageAt;
        this.candidateUnreadCount = candidateUnreadCount;
        this.recruiterUnreadCount = recruiterUnreadCount;
    }

    UUID getId() { return id; }
    UUID getApplicationId() { return applicationId; }
    UUID getJobOfferId() { return jobOfferId; }
    UUID getCandidateId() { return candidateId; }
    UUID getRecruiterId() { return recruiterId; }
    String getJobTitle() { return jobTitle; }
    String getLastMessagePreview() { return lastMessagePreview; }
    Instant getLastMessageAt() { return lastMessageAt; }
    int getCandidateUnreadCount() { return candidateUnreadCount; }
    int getRecruiterUnreadCount() { return recruiterUnreadCount; }
}
