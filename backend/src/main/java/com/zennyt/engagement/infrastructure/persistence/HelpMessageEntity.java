package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_messages", schema = "engagement",
    indexes = @Index(name = "idx_engagement_help_messages_chat", columnList = "help_chat_id, sent_at, id"))
class HelpMessageEntity {
    @Id private UUID id;
    @Column(name = "help_chat_id", nullable = false) private UUID helpChatId;
    /** Clé étrangère {@code engagement.help_chats(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #helpChatId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "help_chat_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "help_messages_help_chat_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private HelpChatEntity helpChat;
    @Column(nullable = false, length = Length.LONG32) private String text;
    @Column(name = "sent_at", nullable = false) private Instant timestamp;
    @Column(name = "from_user", nullable = false) private boolean fromUser;
    protected HelpMessageEntity() {}
    HelpMessageEntity(UUID id, UUID helpChatId, String text, Instant timestamp, boolean fromUser) {
        this.id = id; this.helpChatId = helpChatId; this.text = text;
        this.timestamp = timestamp; this.fromUser = fromUser;
    }
    UUID getId() { return id; } UUID getHelpChatId() { return helpChatId; }
    String getText() { return text; } Instant getTimestamp() { return timestamp; }
    boolean isFromUser() { return fromUser; }
}
