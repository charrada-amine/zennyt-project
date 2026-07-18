package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

interface JpaPollOptionRepository extends JpaRepository<PollOptionEntity, UUID> {
    List<PollOptionEntity> findByPostId(UUID postId);
    void deleteByPostId(UUID postId);
}
