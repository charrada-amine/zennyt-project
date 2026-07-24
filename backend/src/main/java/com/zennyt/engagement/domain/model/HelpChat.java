package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public class HelpChat {
    private final UUID id;
    private final UUID userId;
    private final String title;
    private final String subtitle;
    private Instant lastMessageAt;

    private HelpChat(UUID id, UUID userId, String title, String subtitle, Instant lastMessageAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        if (title == null || title.isBlank()) throw new IllegalArgumentException("Titre obligatoire");
        if (subtitle == null || subtitle.isBlank()) throw new IllegalArgumentException("Sous-titre obligatoire");
        this.title = title;
        this.subtitle = subtitle;
        this.lastMessageAt = lastMessageAt;
    }

    public static HelpChat create(UUID userId, String title, String subtitle) {
        return new HelpChat(UUID.randomUUID(), userId, title, subtitle, null);
    }

    public static HelpChat rehydrate(UUID id, UUID userId, String title,
                                     String subtitle, Instant lastMessageAt) {
        return new HelpChat(id, userId, title, subtitle, lastMessageAt);
    }

    public HelpMessage recordMessage(String text, boolean fromUser) {
        HelpMessage message = HelpMessage.create(id, text, fromUser);
        lastMessageAt = message.timestamp();
        return message;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String title() { return title; }
    public String subtitle() { return subtitle; }
    public Instant lastMessageAt() { return lastMessageAt; }

    public record HelpMessage(UUID id, UUID helpChatId, String text,
                              Instant timestamp, boolean fromUser) {
        public HelpMessage {
            Objects.requireNonNull(id, "id");
            Objects.requireNonNull(helpChatId, "helpChatId");
            if (text == null || text.isBlank()) throw new IllegalArgumentException("Message obligatoire");
            Objects.requireNonNull(timestamp, "timestamp");
        }
        public static HelpMessage create(UUID helpChatId, String text, boolean fromUser) {
            return new HelpMessage(UUID.randomUUID(), helpChatId, text.trim(), Instant.now(), fromUser);
        }
    }
}
