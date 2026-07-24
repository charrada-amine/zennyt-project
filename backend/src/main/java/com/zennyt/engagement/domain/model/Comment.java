package com.zennyt.engagement.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public record Comment(UUID id, UUID postId, UUID authorId, String content, Instant createdAt) {
    public Comment {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(postId, "postId");
        Objects.requireNonNull(authorId, "authorId");
        if (content == null || content.isBlank()) throw new IllegalArgumentException("Commentaire obligatoire");
        Objects.requireNonNull(createdAt, "createdAt");
    }

    public static Comment create(UUID postId, UUID authorId, String content) {
        return new Comment(UUID.randomUUID(), postId, authorId, content.trim(), Instant.now());
    }
}
