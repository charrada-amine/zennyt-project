package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.NotificationType;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Notification interne alignée sur le schéma OpenAPI cible. */
public class Notification {

    private final UUID id;
    private final UUID userId;
    private final NotificationType type;
    private final String title;
    private final String body;
    private final String actionUrl;
    private boolean read;
    private final Instant createdAt;

    private Notification(UUID id, UUID userId, NotificationType type, String title,
                         String body, String actionUrl, boolean read, Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.type = Objects.requireNonNull(type, "type");
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Le titre est obligatoire");
        }
        if (body == null || body.isBlank()) {
            throw new IllegalArgumentException("Le contenu est obligatoire");
        }
        this.title = title;
        this.body = body;
        this.actionUrl = actionUrl;
        this.read = read;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
    }

    public static Notification create(UUID userId, NotificationType type, String title,
                                      String body, String actionUrl) {
        return new Notification(UUID.randomUUID(), userId, type, title, body,
            actionUrl, false, Instant.now());
    }

    public static Notification rehydrate(UUID id, UUID userId, NotificationType type,
                                         String title, String body, String actionUrl,
                                         boolean read, Instant createdAt) {
        return new Notification(id, userId, type, title, body, actionUrl, read, createdAt);
    }

    public void markAsRead() { read = true; }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public NotificationType type() { return type; }
    public String title() { return title; }
    public String body() { return body; }
    public String actionUrl() { return actionUrl; }
    public boolean isRead() { return read; }
    public Instant createdAt() { return createdAt; }
}
