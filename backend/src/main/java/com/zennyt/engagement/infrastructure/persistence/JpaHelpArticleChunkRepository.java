package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface JpaHelpArticleChunkRepository extends JpaRepository<HelpArticleChunkEntity, UUID> {
    List<HelpArticleChunkEntity> findByArticleIdOrderByPosition(UUID articleId);
    void deleteByArticleId(UUID articleId);
}
