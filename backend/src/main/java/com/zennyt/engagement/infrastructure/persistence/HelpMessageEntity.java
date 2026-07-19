package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_messages", schema = "engagement")
class HelpMessageEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID helpChatId;
    @Column(nullable = false, columnDefinition = "TEXT") private String text;
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
