package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.shared.application.EmbeddingCodec;
import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "help_article_chunks", schema = "engagement")
class HelpArticleChunkEntity {
    @Id private UUID id;
    @Column(nullable = false) private UUID articleId;
    @Column(nullable = false) private int position;
    @Column(columnDefinition = "TEXT", nullable = false) private String text;
    @Column(columnDefinition = "TEXT") private String embedding;
    @Column(nullable = false) private String sourceHash;

    protected HelpArticleChunkEntity() {}

    HelpArticleChunkEntity(HelpArticleChunk chunk) {
        this.id = chunk.id();
        apply(chunk);
    }

    void apply(HelpArticleChunk chunk) {
        this.articleId = chunk.articleId();
        this.position = chunk.position();
        this.text = chunk.text();
        this.embedding = EmbeddingCodec.toJson(chunk.embedding());
        this.sourceHash = chunk.sourceHash();
    }

    HelpArticleChunk toDomain() {
        return new HelpArticleChunk(id, articleId, position, text,
            EmbeddingCodec.fromJson(embedding), sourceHash);
    }
}
