package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "conversations", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "conversations_application_id_key", columnNames = {"application_id"}),
    indexes = {
        @Index(name = "idx_engagement_conversations_candidate", columnList = "candidate_id, last_message_at DESC"),
        @Index(name = "idx_engagement_conversations_recruiter", columnList = "recruiter_id, last_message_at DESC")})
@Check(name = "conversations_candidate_unread_count_check", constraints = "candidate_unread_count >= 0")
@Check(name = "conversations_recruiter_unread_count_check", constraints = "recruiter_unread_count >= 0")
@Check(name = "engagement_conversation_distinct_participants", constraints = "candidate_id <> recruiter_id")
class ConversationEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID applicationId;
    @Column(nullable = false) private UUID jobOfferId;
    @Column(nullable = false) private UUID candidateId;
    @Column(nullable = false) private UUID recruiterId;
    private String jobTitle;
    @ColumnDefault("''") @Column(nullable = false, length = 103) private String lastMessagePreview;
    private Instant lastMessageAt;
    @ColumnDefault("0") @Column(nullable = false) private int candidateUnreadCount;
    @ColumnDefault("0") @Column(nullable = false) private int recruiterUnreadCount;
    @Version @ColumnDefault("0") private long version;

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
