package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Définition JPA de la table {@code engagement.post_likes}.
 *
 * <p>Les lectures et écritures passent par les requêtes natives de
 * {@link JpaPostRepository} : cette entité ne sert qu'à faire de JPA la source du schéma
 * de la table ; elle n'est pas utilisée pour accéder aux données.
 */
@Entity
@Table(name = "post_likes", schema = "engagement",
    // Fixe l'ordre des colonnes de la clé primaire (fusionné dans post_likes_pkey).
    uniqueConstraints = @UniqueConstraint(name = "post_likes_pkey", columnNames = {"post_id", "user_id"}))
@IdClass(PostLikeEntity.Key.class)
class PostLikeEntity {

    @Id
    @Column(name = "post_id", nullable = false)
    private UUID postId;

    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    /** Clé étrangère {@code engagement.posts(id) ON DELETE CASCADE} ; lecture seule. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", insertable = false, updatable = false,
        foreignKey = @ForeignKey(name = "post_likes_post_id_fkey"))
    @OnDelete(action = OnDeleteAction.CASCADE)
    private PostEntity post;

    protected PostLikeEntity() {
    }

    /** Clé primaire composite (post_id, user_id). */
    public static class Key implements Serializable {
        private UUID postId;
        private UUID userId;

        public Key() {
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key other)) return false;
            return Objects.equals(postId, other.postId)
                && Objects.equals(userId, other.userId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(postId, userId);
        }
    }
}
