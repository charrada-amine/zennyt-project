package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

interface JpaPostMediaRepository extends JpaRepository<PostMediaEntity, UUID> {
    List<PostMediaEntity> findByPostId(UUID postId);
    List<PostMediaEntity> findByPostIdIn(List<UUID> postIds);
    void deleteByPostId(UUID postId);
}
