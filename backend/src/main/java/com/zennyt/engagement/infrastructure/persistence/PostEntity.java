package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.vo.PostVisibility;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "posts", schema = "engagement")
class PostEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID authorId;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private PostVisibility visibility;
    @Column(columnDefinition = "TEXT") private String content;
    private UUID pollId;
    @Column(columnDefinition = "TEXT") private String pollQuestion;
    private String pollDuration;
    @Column(nullable = false) private int commentsCount;
    @Column(nullable = false) private Instant createdAt;
    @Version private long version;

    protected PostEntity() {}

    PostEntity(UUID id, UUID authorId, PostVisibility visibility, String content,
               UUID pollId, String pollQuestion, String pollDuration,
               int commentsCount, Instant createdAt) {
        this.id = id;
        this.createdAt = createdAt;
        update(authorId, visibility, content, pollId, pollQuestion, pollDuration, commentsCount);
    }

    void update(UUID authorId, PostVisibility visibility, String content, UUID pollId,
                String pollQuestion, String pollDuration, int commentsCount) {
        this.authorId = authorId;
        this.visibility = visibility;
        this.content = content;
        this.pollId = pollId;
        this.pollQuestion = pollQuestion;
        this.pollDuration = pollDuration;
        this.commentsCount = commentsCount;
    }

    UUID getId() { return id; }
    UUID getAuthorId() { return authorId; }
    PostVisibility getVisibility() { return visibility; }
    String getContent() { return content; }
    UUID getPollId() { return pollId; }
    String getPollQuestion() { return pollQuestion; }
    String getPollDuration() { return pollDuration; }
    int getCommentsCount() { return commentsCount; }
    Instant getCreatedAt() { return createdAt; }
}
