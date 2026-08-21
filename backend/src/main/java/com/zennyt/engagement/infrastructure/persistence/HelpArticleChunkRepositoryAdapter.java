package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticleChunk;
import com.zennyt.engagement.domain.repository.HelpArticleChunkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class HelpArticleChunkRepositoryAdapter implements HelpArticleChunkRepository {
    private final JpaHelpArticleChunkRepository jpa;

    @Override
    public HelpArticleChunk save(HelpArticleChunk chunk) {
        HelpArticleChunkEntity entity = jpa.findById(chunk.id())
            .orElseGet(() -> new HelpArticleChunkEntity(chunk));
        entity.apply(chunk);
        return jpa.save(entity).toDomain();
    }

    @Override
    public List<HelpArticleChunk> findByArticleId(UUID articleId) {
        return jpa.findByArticleIdOrderByPosition(articleId).stream()
            .map(HelpArticleChunkEntity::toDomain).toList();
    }

    @Override
    public List<HelpArticleChunk> findAll() {
        return jpa.findAll().stream().map(HelpArticleChunkEntity::toDomain).toList();
    }

    @Override
    @Transactional
    public void deleteByArticleId(UUID articleId) {
        jpa.deleteByArticleId(articleId);
    }
}
