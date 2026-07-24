package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.MediaType;
import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "post_media", schema = "engagement")
class PostMediaEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID postId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private MediaType type;
    @Column(nullable = false, columnDefinition = "TEXT") private String url;
    protected PostMediaEntity() {}
    PostMediaEntity(UUID id, UUID postId, MediaType type, String url) {
        this.id = id; this.postId = postId; this.type = type; this.url = url;
    }
    UUID getId() { return id; }
    UUID getPostId() { return postId; }
    MediaType getType() { return type; }
    String getUrl() { return url; }
}
