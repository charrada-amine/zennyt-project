package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "friendships", schema = "engagement")
class FriendshipEntity {
    @EmbeddedId private FriendshipId id;
    @Column(nullable = false) private Instant createdAt;
    protected FriendshipEntity() {}
}
