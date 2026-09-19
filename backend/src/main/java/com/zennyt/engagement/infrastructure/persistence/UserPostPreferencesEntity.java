package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "user_post_preferences", schema = "engagement")
class UserPostPreferencesEntity {
    @Id private UUID userId;
    @Column(nullable = false) private Instant updatedAt;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "hidden_posts", schema = "engagement",
        joinColumns = @JoinColumn(name = "user_id"),
        // Ordre des colonnes de la clé primaire (user_id, post_id), fusionné dans hidden_posts_pkey.
        uniqueConstraints = @UniqueConstraint(name = "hidden_posts_pkey", columnNames = {"user_id", "post_id"}),
        // @OnDelete est refusé sur une @ElementCollection : la cascade est écrite dans la définition.
        foreignKey = @ForeignKey(name = "hidden_posts_user_id_fkey", foreignKeyDefinition =
            "FOREIGN KEY (user_id) REFERENCES engagement.user_post_preferences (user_id) ON DELETE CASCADE"))
    @Column(name = "post_id", nullable = false)
    private Set<UUID> hiddenPostIds = new LinkedHashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "blocked_authors", schema = "engagement",
        joinColumns = @JoinColumn(name = "user_id"),
        uniqueConstraints = @UniqueConstraint(name = "blocked_authors_pkey", columnNames = {"user_id", "author_id"}),
        foreignKey = @ForeignKey(name = "blocked_authors_user_id_fkey", foreignKeyDefinition =
            "FOREIGN KEY (user_id) REFERENCES engagement.user_post_preferences (user_id) ON DELETE CASCADE"))
    @Column(name = "author_id", nullable = false)
    private Set<UUID> blockedAuthorIds = new LinkedHashSet<>();

    protected UserPostPreferencesEntity() {}
    UserPostPreferencesEntity(UUID userId, Set<UUID> hidden, Set<UUID> blocked) {
        this.userId = userId; this.updatedAt = Instant.now();
        this.hiddenPostIds = hidden; this.blockedAuthorIds = blocked;
    }
    UUID getUserId() { return userId; }
    Set<UUID> getHiddenPostIds() { return hiddenPostIds; }
    Set<UUID> getBlockedAuthorIds() { return blockedAuthorIds; }
}
