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
        joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "post_id")
    private Set<UUID> hiddenPostIds = new LinkedHashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "blocked_authors", schema = "engagement",
        joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "author_id")
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
