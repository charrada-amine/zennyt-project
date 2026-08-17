package com.zennyt.games.infrastructure.catalog;

import com.zennyt.games.domain.catalog.DecisionFormCatalog;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.vo.OptionQuality;
import com.zennyt.games.infrastructure.persistence.DecisionScenarioEntity;
import com.zennyt.games.infrastructure.persistence.JpaDecisionScenarioRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Catalogue « Je Décide » adossé à la base (V59) — implémentation vivante des deux
 * ports : {@link DecisionScenarioCatalog} pour la notation,
 * {@link DecisionFormCatalog} pour la présentation.
 *
 * <p>Remplace {@code JsonDecisionScenarioCatalog}, qui lisait la banque en ressource.
 * Le passage en base ne change <b>aucun score</b> : les mêmes 120 items, les mêmes
 * qualités d'option. Le JSON reste dans le dépôt comme source du seed Flyway.
 *
 * <p>Le contenu servi passe par le port de présentation, jamais par le port de
 * notation : ce dernier ne connaît que les qualités et n'a rien à publier.
 */
@Component
public class DatabaseDecisionScenarioCatalog
    implements DecisionScenarioCatalog, DecisionFormCatalog {

    private final JpaDecisionScenarioRepository repository;

    public DatabaseDecisionScenarioCatalog(JpaDecisionScenarioRepository repository) {
        this.repository = repository;
    }

    // ── Port de notation ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Optional<Item> item(String itemId) {
        return repository.findByItemId(itemId).map(DatabaseDecisionScenarioCatalog::toScoringItem);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isEmpty() {
        return repository.count() == 0;
    }

    private static Item toScoringItem(DecisionScenarioEntity entity) {
        Map<String, OptionQuality> qualities = new LinkedHashMap<>();
        entity.getOptions().forEach(o -> qualities.put(o.getOptionId(), o.getQuality()));
        return new Item(entity.getItemId(), entity.getDimension(), entity.getFormat(),
            entity.isProvisionalScoring(), qualities);
    }

    // ── Port de présentation ────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<Content> form(String formCode) {
        List<DecisionScenarioEntity> items = repository.findFormItems(formCode);
        if (items.isEmpty()) {
            return List.of();
        }
        // Les items DT n'ont pas de vignette propre : ils réutilisent celle de leur
        // homologue II (DT-7 → II-7). On résout la référence ici, pour que le client
        // reçoive un item auto-suffisant et n'ait aucune jointure à refaire.
        Set<String> referenced = items.stream()
            .map(DecisionScenarioEntity::getVignetteRef)
            .filter(java.util.Objects::nonNull)
            .collect(Collectors.toSet());
        Map<String, String> vignetteByItemId = referenced.isEmpty()
            ? Map.of()
            : repository.findByItemIdIn(referenced).stream()
                .collect(Collectors.toMap(
                    DecisionScenarioEntity::getItemId, DecisionScenarioEntity::getVignette));

        return items.stream().map(e -> toContent(e, vignetteByItemId)).toList();
    }

    private static Content toContent(DecisionScenarioEntity e, Map<String, String> vignettes) {
        String vignette = e.getVignette() != null
            ? e.getVignette()
            : vignettes.get(e.getVignetteRef());
        if (vignette == null) {
            throw new IllegalStateException(
                "Vignette introuvable pour l'item " + e.getItemId()
                    + " (référence : " + e.getVignetteRef() + ")");
        }
        return new Content(
            e.getItemId(),
            e.getDimension(),
            e.getFormat(),
            e.getPairId(),
            vignette,
            e.getTask(),
            e.isProvisionalScoring(),
            e.getOptions().stream()
                .map(o -> new Content.Option(o.getOptionId(), o.getLabel(), o.getQuality()))
                .toList());
    }
}
