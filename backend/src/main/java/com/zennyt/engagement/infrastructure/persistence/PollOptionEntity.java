package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "poll_options", schema = "engagement")
class PollOptionEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID postId;
    @Column(nullable = false, columnDefinition = "TEXT") private String text;
    @Column(nullable = false) private int voteCount;
    protected PollOptionEntity() {}
    PollOptionEntity(UUID id, UUID postId, String text, int voteCount) {
        this.id = id; this.postId = postId; this.text = text; this.voteCount = voteCount;
    }
    UUID getId() { return id; }
    UUID getPostId() { return postId; }
    String getText() { return text; }
    int getVoteCount() { return voteCount; }
}
