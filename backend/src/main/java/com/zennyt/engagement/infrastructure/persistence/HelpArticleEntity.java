package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticle;
import jakarta.persistence.*;
import org.hibernate.Length;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.Comment;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "help_articles", schema = "engagement",
    uniqueConstraints = @UniqueConstraint(name = "help_articles_slug_locale_unique", columnNames = {"slug", "locale"}),
    indexes = @Index(name = "idx_engagement_help_articles_audience", columnList = "locale, audience"))
@Check(name = "help_articles_audience_valide", constraints = "audience IN ('CANDIDATE', 'RECRUITER', 'BOTH')")
// Apostrophes doublées : Hibernate 6.5 insère le texte de @Comment tel quel entre quotes SQL.
@Comment("Documentation destinee aux utilisateurs, source du volet documentaire de l''agent.\n"
    + "     Synchronisee depuis les fichiers de resources au demarrage — ne pas editer a la main.")
class HelpArticleEntity {
    @Id private UUID id;
    @Column(nullable = false, length = Length.LONG32) private String slug;
    @Column(nullable = false, length = Length.LONG32) private String locale;
    @Comment("CANDIDATE, RECRUITER ou BOTH — un article de creation d''offre n''a rien a dire a un candidat.")
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = Length.LONG32) private HelpArticle.Audience audience;
    @Column(nullable = false, length = Length.LONG32) private String category;
    @Column(nullable = false, length = Length.LONG32) private String title;
    @Column(length = Length.LONG32, nullable = false) private String body;
    @Column(nullable = false, length = Length.LONG32) private String contentHash;
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
