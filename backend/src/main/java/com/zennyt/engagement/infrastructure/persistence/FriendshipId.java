package com.zennyt.engagement.infrastructure.persistence;

import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class FriendshipId implements Serializable {
    private UUID userId;
    private UUID friendId;

    protected FriendshipId() {
    }

    public FriendshipId(UUID userId, UUID friendId) {
        this.userId = Objects.requireNonNull(userId);
        this.friendId = Objects.requireNonNull(friendId);
    }

    public UUID getUserId() { return userId; }
    public UUID getFriendId() { return friendId; }

    @Override public boolean equals(Object value) {
        if (this == value) return true;
        if (!(value instanceof FriendshipId other)) return false;
        return userId.equals(other.userId) && friendId.equals(other.friendId);
    }

    @Override public int hashCode() { return Objects.hash(userId, friendId); }
}
