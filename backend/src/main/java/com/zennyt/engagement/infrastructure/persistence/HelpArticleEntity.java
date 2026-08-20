package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticle;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_articles", schema = "engagement")
class HelpArticleEntity {
    @Id private UUID id;
    @Column(nullable = false) private String slug;
    @Column(nullable = false) private String locale;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private HelpArticle.Audience audience;
    @Column(nullable = false) private String category;
    @Column(nullable = false) private String title;
    @Column(columnDefinition = "TEXT", nullable = false) private String body;
    @Column(nullable = false) private String contentHash;
    @Column(nullable = false) private Instant updatedAt;

    protected HelpArticleEntity() {}

    HelpArticleEntity(HelpArticle article) {
        this.id = article.id();
        apply(article);
    }

    void apply(HelpArticle article) {
        this.slug = article.slug();
        this.locale = article.locale();
        this.audience = article.audience();
        this.category = article.category();
        this.title = article.title();
        this.body = article.body();
        this.contentHash = article.contentHash();
        this.updatedAt = article.updatedAt();
    }

    HelpArticle toDomain() {
        return new HelpArticle(id, slug, locale, audience, category, title, body,
            contentHash, updatedAt);
    }
}
