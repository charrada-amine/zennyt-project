package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Conversation unique partagée par un candidat et un recruteur. */
public class Conversation {

    private static final int PREVIEW_LENGTH = 100;

    private final UUID id;
    private final UUID applicationId;
    private final UUID jobOfferId;
    private final UUID candidateId;
    private final UUID recruiterId;
    private final String jobTitle;
    private String lastMessagePreview;
    private Instant lastMessageAt;
    private int candidateUnreadCount;
    private int recruiterUnreadCount;

    private Conversation(UUID id, UUID applicationId, UUID jobOfferId,
                         UUID candidateId, UUID recruiterId, String jobTitle,
                         String lastMessagePreview, Instant lastMessageAt,
                         int candidateUnreadCount, int recruiterUnreadCount) {
        this.id = Objects.requireNonNull(id, "id");
        this.applicationId = Objects.requireNonNull(applicationId, "applicationId");
        this.jobOfferId = Objects.requireNonNull(jobOfferId, "jobOfferId");
        this.candidateId = Objects.requireNonNull(candidateId, "candidateId");
        this.recruiterId = Objects.requireNonNull(recruiterId, "recruiterId");
        if (candidateId.equals(recruiterId)) {
            throw new IllegalArgumentException("Les participants doivent être différents");
        }
        this.jobTitle = jobTitle;
        this.lastMessagePreview = lastMessagePreview == null ? "" : lastMessagePreview;
        this.lastMessageAt = lastMessageAt;
        this.candidateUnreadCount = nonNegative(candidateUnreadCount, "candidateUnreadCount");
        this.recruiterUnreadCount = nonNegative(recruiterUnreadCount, "recruiterUnreadCount");
    }

    public static Conversation create(UUID applicationId, UUID jobOfferId,
                                      UUID candidateId, UUID recruiterId, String jobTitle) {
        return new Conversation(UUID.randomUUID(), applicationId, jobOfferId,
            candidateId, recruiterId, jobTitle, "", null, 0, 0);
    }

    public static Conversation rehydrate(UUID id, UUID applicationId, UUID jobOfferId,
                                         UUID candidateId, UUID recruiterId, String jobTitle,
                                         String lastMessagePreview, Instant lastMessageAt,
                                         int candidateUnreadCount, int recruiterUnreadCount) {
        return new Conversation(id, applicationId, jobOfferId, candidateId, recruiterId, jobTitle,
            lastMessagePreview, lastMessageAt, candidateUnreadCount, recruiterUnreadCount);
    }

    public Message recordMessage(UUID senderId, String content,
                                 MessageContentType contentType, String attachmentUrl) {
        MessageSenderRole role = roleOf(senderId);
        Message message = Message.create(id, senderId, role, content, contentType, attachmentUrl);
        lastMessagePreview = preview(message.content());
        lastMessageAt = message.sentAt();
        if (role == MessageSenderRole.CANDIDATE) {
            recruiterUnreadCount++;
        } else {
            candidateUnreadCount++;
        }
        return message;
    }

    public void markAsReadBy(UUID participantId) {
        MessageSenderRole role = roleOf(participantId);
        if (role == MessageSenderRole.CANDIDATE) {
            candidateUnreadCount = 0;
        } else {
            recruiterUnreadCount = 0;
        }
    }

    public boolean isParticipant(UUID userId) {
        return candidateId.equals(userId) || recruiterId.equals(userId);
    }

    public MessageSenderRole roleOf(UUID userId) {
        if (candidateId.equals(userId)) return MessageSenderRole.CANDIDATE;
        if (recruiterId.equals(userId)) return MessageSenderRole.RECRUITER;
        throw new IllegalArgumentException("L'utilisateur ne participe pas à cette conversation");
    }

    public UUID counterpartIdFor(UUID userId) {
        return roleOf(userId) == MessageSenderRole.CANDIDATE ? recruiterId : candidateId;
    }

    public int unreadCountFor(UUID userId) {
        return roleOf(userId) == MessageSenderRole.CANDIDATE
            ? candidateUnreadCount : recruiterUnreadCount;
    }

    public UUID id() { return id; }
    public UUID applicationId() { return applicationId; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID candidateId() { return candidateId; }
    public UUID recruiterId() { return recruiterId; }
    public String jobTitle() { return jobTitle; }
    public String lastMessagePreview() { return lastMessagePreview; }
    public Instant lastMessageAt() { return lastMessageAt; }
    public int candidateUnreadCount() { return candidateUnreadCount; }
    public int recruiterUnreadCount() { return recruiterUnreadCount; }

    private static String preview(String content) {
        return content.length() > PREVIEW_LENGTH
            ? content.substring(0, PREVIEW_LENGTH) + "..." : content;
    }

    private static int nonNegative(int value, String field) {
        if (value < 0) throw new IllegalArgumentException(field + " doit être positif");
        return value;
    }

    public record Message(UUID id, UUID conversationId, UUID senderId,
                          MessageSenderRole senderRole, String content,
                          MessageContentType contentType, String attachmentUrl,
                          Instant sentAt, Instant readAt) {

        public Message {
            Objects.requireNonNull(id, "id");
            Objects.requireNonNull(conversationId, "conversationId");
            Objects.requireNonNull(senderId, "senderId");
            Objects.requireNonNull(senderRole, "senderRole");
            if (content == null || content.isBlank()) {
                throw new IllegalArgumentException("Le contenu du message est obligatoire");
            }
            Objects.requireNonNull(contentType, "contentType");
            Objects.requireNonNull(sentAt, "sentAt");
        }

        public static Message create(UUID conversationId, UUID senderId,
                                     MessageSenderRole senderRole, String content,
                                     MessageContentType contentType, String attachmentUrl) {
            return new Message(UUID.randomUUID(), conversationId, senderId, senderRole,
                content, contentType == null ? MessageContentType.TEXT : contentType,
                attachmentUrl, Instant.now(), null);
        }

        public static Message rehydrate(UUID id, UUID conversationId, UUID senderId,
                                        MessageSenderRole senderRole, String content,
                                        MessageContentType contentType, String attachmentUrl,
                                        Instant sentAt, Instant readAt) {
            return new Message(id, conversationId, senderId, senderRole, content,
                contentType, attachmentUrl, sentAt, readAt);
        }
    }
}
