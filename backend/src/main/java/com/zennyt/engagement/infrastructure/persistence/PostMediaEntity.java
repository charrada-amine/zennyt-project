package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.MediaType;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.UUID;

@Entity
@Table(name = "post_media", schema = "engagement")
class PostMediaEntity {
    @Id private UUID id;
    @Column(name = "post_id", nullable = false) private UUID postId;
    /** Clé étrangère {@code engagement.posts(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #postId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "post_media_post_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private PostEntity post;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private MediaType type;
    @Column(nullable = false, length = Length.LONG32) private String url;
    protected PostMediaEntity() {}
    PostMediaEntity(UUID id, UUID postId, MediaType type, String url) {
        this.id = id; this.postId = postId; this.type = type; this.url = url;
    }
    UUID getId() { return id; }
    UUID getPostId() { return postId; }
    MediaType getType() { return type; }
    String getUrl() { return url; }
}
