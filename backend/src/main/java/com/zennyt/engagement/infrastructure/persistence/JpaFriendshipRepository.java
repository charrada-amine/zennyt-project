package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

interface JpaFriendshipRepository extends JpaRepository<FriendshipEntity, FriendshipId> {}
