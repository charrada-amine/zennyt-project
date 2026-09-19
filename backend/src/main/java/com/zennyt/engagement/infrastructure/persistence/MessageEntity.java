package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "messages", schema = "engagement",
    indexes = @Index(name = "idx_engagement_messages_conversation_sent", columnList = "conversation_id, sent_at DESC, id DESC"))
class MessageEntity {
    @Id private UUID id;
    @Column(name = "conversation_id", nullable = false) private UUID conversationId;
    /** Clé étrangère {@code engagement.conversations(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #conversationId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "messages_conversation_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private ConversationEntity conversation;
    @Column(nullable = false) private UUID senderId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private MessageSenderRole senderRole;
    @Column(nullable = false, length = Length.LONG32) private String content;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private MessageContentType contentType;
    @Column(length = Length.LONG32) private String attachmentUrl;
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
