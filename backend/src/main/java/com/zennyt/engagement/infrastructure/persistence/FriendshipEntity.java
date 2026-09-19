package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.annotations.Check;
import java.time.Instant;

@Entity
@Table(name = "friendships", schema = "engagement",
    // Fixe l'ordre des colonnes de la clé primaire (user_id, friend_id) : Hibernate les
    // trierait sinon par nom d'attribut. Contrainte fusionnée dans friendships_pkey.
    uniqueConstraints = @UniqueConstraint(name = "friendships_pkey", columnNames = {"user_id", "friend_id"}))
@Check(name = "engagement_friendship_distinct_users", constraints = "user_id <> friend_id")
class FriendshipEntity {
    @EmbeddedId private FriendshipId id;
    @Column(nullable = false) private Instant createdAt;
    protected FriendshipEntity() {}
}
