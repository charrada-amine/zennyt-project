package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_chats", schema = "engagement")
class HelpChatEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID userId;
    @Column(nullable = false) private String title;
    @Column(nullable = false) private String subtitle;
    private Instant lastMessageAt;
    @Version private long version;
    protected HelpChatEntity() {}
    HelpChatEntity(UUID id, UUID userId, String title, String subtitle, Instant lastMessageAt) {
        this.id = id; this.userId = userId; this.title = title;
        this.subtitle = subtitle; this.lastMessageAt = lastMessageAt;
    }
    void update(Instant value) { this.lastMessageAt = value; }
    UUID getId() { return id; } UUID getUserId() { return userId; }
    String getTitle() { return title; } String getSubtitle() { return subtitle; }
    Instant getLastMessageAt() { return lastMessageAt; }
}
