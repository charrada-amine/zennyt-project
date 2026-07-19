package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

interface JpaCommentRepository extends JpaRepository<CommentEntity, UUID> {
    List<CommentEntity> findByPostIdOrderByCreatedAtAscIdAsc(UUID postId);
}
