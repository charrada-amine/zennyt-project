package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

interface JpaHelpArticleRepository extends JpaRepository<HelpArticleEntity, UUID> {
    Optional<HelpArticleEntity> findBySlugAndLocale(String slug, String locale);
    List<HelpArticleEntity> findByLocale(String locale);
    void deleteBySlugAndLocale(String slug, String locale);
}
