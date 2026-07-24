package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "messages", schema = "engagement")
class MessageEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID conversationId;
    @Column(nullable = false) private UUID senderId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private MessageSenderRole senderRole;
    @Column(nullable = false, columnDefinition = "TEXT") private String content;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private MessageContentType contentType;
    @Column(columnDefinition = "TEXT") private String attachmentUrl;
    @Column(nullable = false) private Instant sentAt;
    private Instant readAt;

    protected MessageEntity() {}

    MessageEntity(UUID id, UUID conversationId, UUID senderId, MessageSenderRole senderRole,
                  String content, MessageContentType contentType, String attachmentUrl,
                  Instant sentAt, Instant readAt) {
        this.id = id;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.senderRole = senderRole;
        this.content = content;
        this.contentType = contentType;
        this.attachmentUrl = attachmentUrl;
        this.sentAt = sentAt;
        this.readAt = readAt;
    }

    UUID getId() { return id; }
    UUID getConversationId() { return conversationId; }
    UUID getSenderId() { return senderId; }
    MessageSenderRole getSenderRole() { return senderRole; }
    String getContent() { return content; }
    MessageContentType getContentType() { return contentType; }
    String getAttachmentUrl() { return attachmentUrl; }
    Instant getSentAt() { return sentAt; }
    Instant getReadAt() { return readAt; }
}
