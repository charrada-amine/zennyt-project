package com.zennyt.games.infrastructure.catalog;

import com.zennyt.games.domain.catalog.EmotionalRadarSceneCatalog;
import com.zennyt.games.domain.vo.EmotionalRadarScene;
import com.zennyt.games.infrastructure.persistence.EmotionalRadarSceneEntity;
import com.zennyt.games.infrastructure.persistence.JpaEmotionalRadarSceneRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Catalogue de scènes adossé à la base ({@code V25}).
 *
 * <p>Contrairement à {@code EmptyDecisionScenarioCatalog}, cette implémentation
 * n'est pas vide : trois scènes rédigées sont livrées par la migration. Les douze
 * scènes restantes ne sont pas inventées — elles seront simplement insérées quand
 * le psychologue les fournira, sans aucun changement de code.
 */
@Component
public class DatabaseEmotionalRadarSceneCatalog implements EmotionalRadarSceneCatalog {

    private final JpaEmotionalRadarSceneRepository repository;

    public DatabaseEmotionalRadarSceneCatalog(JpaEmotionalRadarSceneRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<EmotionalRadarScene> scenes() {
        return repository.findByActiveTrueOrderBySceneOrderAsc().stream()
            .map(EmotionalRadarSceneEntity::toDomain)
            .toList();
    }

    @Override
    public Optional<EmotionalRadarScene> findById(UUID sceneId) {
        return repository.findById(sceneId)
            .filter(EmotionalRadarSceneEntity::isActive)
            .map(EmotionalRadarSceneEntity::toDomain);
    }
}
