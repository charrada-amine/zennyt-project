package com.zennyt.engagement.domain.repository;

import java.util.UUID;

public interface FriendshipRepository {
    boolean areFriends(UUID firstUserId, UUID secondUserId);
}
