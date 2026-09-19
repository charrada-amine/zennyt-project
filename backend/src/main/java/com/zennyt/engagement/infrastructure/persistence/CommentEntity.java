package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "comments", schema = "engagement",
    indexes = @Index(name = "idx_engagement_comments_post", columnList = "post_id, created_at, id"))
class CommentEntity {
    @Id private UUID id;
    @Column(name = "post_id", nullable = false) private UUID postId;
    /** Clé étrangère {@code engagement.posts(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #postId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "comments_post_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private PostEntity post;
    @Column(nullable = false) private UUID authorId;
    @Column(nullable = false, length = Length.LONG32) private String content;
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
