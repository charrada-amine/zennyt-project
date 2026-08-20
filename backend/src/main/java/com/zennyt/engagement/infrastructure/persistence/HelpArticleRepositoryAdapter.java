package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpArticle;
import com.zennyt.engagement.domain.repository.HelpArticleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class HelpArticleRepositoryAdapter implements HelpArticleRepository {
    private final JpaHelpArticleRepository jpa;

    @Override
    public HelpArticle save(HelpArticle article) {
        // Recherche par (slug, locale) et non par identifiant : le chargeur reconstruit un
        // identifiant a chaque demarrage, alors que la cle metier d'un article est son slug.
        HelpArticleEntity entity = jpa.findBySlugAndLocale(article.slug(), article.locale())
            .orElseGet(() -> new HelpArticleEntity(article));
        entity.apply(article);
        return jpa.save(entity).toDomain();
    }

    @Override
    public Optional<HelpArticle> findBySlugAndLocale(String slug, String locale) {
        return jpa.findBySlugAndLocale(slug, locale).map(HelpArticleEntity::toDomain);
    }

    @Override
    public List<HelpArticle> findByLocale(String locale) {
        return jpa.findByLocale(locale).stream().map(HelpArticleEntity::toDomain).toList();
    }

    @Override
    public List<HelpArticle> findAll() {
        return jpa.findAll().stream().map(HelpArticleEntity::toDomain).toList();
    }

    @Override
    @Transactional
    public void deleteBySlugAndLocale(String slug, String locale) {
        jpa.deleteBySlugAndLocale(slug, locale);
    }
}
