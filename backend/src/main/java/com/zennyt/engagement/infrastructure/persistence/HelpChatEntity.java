package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.HelpChatRating;
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
    @Enumerated(EnumType.STRING) private HelpChatRating rating;
    private String ratingComment;
    private Instant ratedAt;
    @Version private long version;
    protected HelpChatEntity() {}
    HelpChatEntity(UUID id, UUID userId, String title, String subtitle, Instant lastMessageAt) {
        this.id = id; this.userId = userId; this.title = title;
        this.subtitle = subtitle; this.lastMessageAt = lastMessageAt;
    }
    void update(Instant value) { this.lastMessageAt = value; }
    void applyRating(HelpChatRating value, String comment, Instant at) {
        this.rating = value; this.ratingComment = comment; this.ratedAt = at;
    }
    UUID getId() { return id; } UUID getUserId() { return userId; }
    String getTitle() { return title; } String getSubtitle() { return subtitle; }
    Instant getLastMessageAt() { return lastMessageAt; }
    HelpChatRating getRating() { return rating; }
    String getRatingComment() { return ratingComment; }
    Instant getRatedAt() { return ratedAt; }
}
