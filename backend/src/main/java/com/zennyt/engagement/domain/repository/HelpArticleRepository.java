package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.HelpArticle;

import java.util.List;
import java.util.Optional;

public interface HelpArticleRepository {
    HelpArticle save(HelpArticle article);
    Optional<HelpArticle> findBySlugAndLocale(String slug, String locale);
    List<HelpArticle> findByLocale(String locale);
    List<HelpArticle> findAll();
    void deleteBySlugAndLocale(String slug, String locale);
}
