package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.NotificationType;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notifications", schema = "engagement", indexes = {
    @Index(name = "idx_engagement_notifications_user_created", columnList = "user_id, created_at DESC"),
    @Index(name = "idx_engagement_notifications_user_unread", columnList = "user_id, is_read, created_at DESC")})
class NotificationEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID userId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 50) private NotificationType type;
    @Column(nullable = false) private String title;
    @Column(nullable = false, length = Length.LONG32) private String body;
    @Column(length = Length.LONG32) private String actionUrl;
    @ColumnDefault("false") @Column(name = "is_read", nullable = false) private boolean read;
    @Column(nullable = false) private Instant createdAt;

    protected NotificationEntity() {}

    NotificationEntity(UUID id, UUID userId, NotificationType type, String title, String body,
                       String actionUrl, boolean read, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.type = type;
        this.title = title;
        this.body = body;
        this.actionUrl = actionUrl;
        this.read = read;
        this.createdAt = createdAt;
    }

    UUID getId() { return id; }
    UUID getUserId() { return userId; }
    NotificationType getType() { return type; }
    String getTitle() { return title; }
    String getBody() { return body; }
    String getActionUrl() { return actionUrl; }
    boolean isRead() { return read; }
    Instant getCreatedAt() { return createdAt; }
}
