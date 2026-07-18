package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "comments", schema = "engagement")
class CommentEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID postId;
    @Column(nullable = false) private UUID authorId;
    @Column(nullable = false, columnDefinition = "TEXT") private String content;
    @Column(nullable = false) private Instant createdAt;
    protected CommentEntity() {}
    CommentEntity(UUID id, UUID postId, UUID authorId, String content, Instant createdAt) {
        this.id = id; this.postId = postId; this.authorId = authorId;
        this.content = content; this.createdAt = createdAt;
    }
    UUID getId() { return id; }
    UUID getPostId() { return postId; }
    UUID getAuthorId() { return authorId; }
    String getContent() { return content; }
    Instant getCreatedAt() { return createdAt; }
}
