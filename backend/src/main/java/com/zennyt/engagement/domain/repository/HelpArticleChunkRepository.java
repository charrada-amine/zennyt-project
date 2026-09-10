package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.HelpArticleChunk;

import java.util.List;
import java.util.UUID;

public interface HelpArticleChunkRepository {
    HelpArticleChunk save(HelpArticleChunk chunk);
    List<HelpArticleChunk> findByArticleId(UUID articleId);
    List<HelpArticleChunk> findAll();
    void deleteByArticleId(UUID articleId);
}
