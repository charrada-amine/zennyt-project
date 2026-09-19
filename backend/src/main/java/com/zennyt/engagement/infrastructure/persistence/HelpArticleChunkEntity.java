package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.shared.application.EmbeddingCodec;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.Comment;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.UUID;

@Entity
// Index partiel idx_engagement_help_chunks_sans_empreinte : db/schema-complements.sql.
@Table(name = "help_article_chunks", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "help_chunks_article_position_unique", columnNames = {"article_id", "position"}),
    indexes = @Index(name = "idx_engagement_help_chunks_article", columnList = "article_id"))
class HelpArticleChunkEntity {
    @Id private UUID id;
    @Column(name = "article_id", nullable = false) private UUID articleId;
    /** Clé étrangère {@code engagement.help_articles(id) ON DELETE CASCADE} ; lecture seule, la colonne est écrite via {@link #articleId}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "article_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "help_article_chunks_article_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private HelpArticleEntity article;
    @Column(nullable = false) private int position;
    @Column(length = Length.LONG32, nullable = false) private String text;
    // Apostrophes doublées : Hibernate 6.5 insère le texte de @Comment tel quel entre quotes SQL.
    @Comment("Empreinte semantique du fragment, ou NULL si le service n''est pas configure —\n"
        + "     la recherche bascule alors sur les mots, jamais sur rien.")
    @Column(length = Length.LONG32) private String embedding;
    @Column(nullable = false, length = Length.LONG32) private String sourceHash;

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
