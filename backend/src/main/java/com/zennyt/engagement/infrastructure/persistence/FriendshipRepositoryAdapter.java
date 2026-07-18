package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.repository.FriendshipRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@RequiredArgsConstructor
public class FriendshipRepositoryAdapter implements FriendshipRepository {
    private final JpaFriendshipRepository jpa;
    @Override public boolean areFriends(UUID firstUserId, UUID secondUserId) {
        return jpa.existsById(new FriendshipId(firstUserId, secondUserId))
            || jpa.existsById(new FriendshipId(secondUserId, firstUserId));
    }
}
