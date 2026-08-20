package com.zennyt.engagement.domain.model;

import com.zennyt.engagement.domain.vo.HelpChatRating;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public class HelpChat {
    private final UUID id;
    private final UUID userId;
    private final String title;
    private final String subtitle;
    private Instant lastMessageAt;
    private HelpChatRating rating;
    private String ratingComment;
    private Instant ratedAt;

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

    public static HelpChat rehydrate(UUID id, UUID userId, String title, String subtitle,
                                     Instant lastMessageAt, HelpChatRating rating,
                                     String ratingComment, Instant ratedAt) {
        HelpChat chat = new HelpChat(id, userId, title, subtitle, lastMessageAt);
        chat.rating = rating;
        chat.ratingComment = ratingComment;
        chat.ratedAt = ratedAt;
        return chat;
    }

    /**
     * Enregistre l'appréciation de l'utilisateur. Repasser sur une conversation déjà
     * notée remplace la note : quelqu'un qui se ravise après une réponse tardive doit
     * pouvoir le dire, et garder la première évaluation serait garder la moins juste.
     *
     * @param comment commentaire libre, facultatif — le formulaire s'ouvre après la note
     *                et peut être fermé sans rien écrire
     */
    public void rate(HelpChatRating value, String comment) {
        this.rating = Objects.requireNonNull(value, "rating");
        this.ratingComment = comment == null || comment.isBlank() ? null : comment.trim();
        this.ratedAt = Instant.now();
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
    public HelpChatRating rating() { return rating; }
    public String ratingComment() { return ratingComment; }
    public Instant ratedAt() { return ratedAt; }

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
