package com.zennyt.games.infrastructure.catalog;

import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * Implémentation vivante <b>VIDE</b> du catalogue « Je Décide ».
 *
 * <p>// EN ATTENTE DU PSYCHOLOGUE — 30 scénarios + étiquetage des options
 * (chaque option étiquetée d'une {@code OptionQuality}). Aucun contenu de
 * scénario n'est inventé ici.
 *
 * <p>Tant que ce catalogue est vide, {@code MiniGame.DECISION_CORE} reste non
 * jouable : une session DECISION ne peut donc pas être complétée en production.
 * Les tests injectent un catalogue de test à la place.
 */
@Component
public class EmptyDecisionScenarioCatalog implements DecisionScenarioCatalog {

    @Override
    public Optional<Item> item(String itemId) {
        return Optional.empty();
    }

    @Override
    public boolean isEmpty() {
        return true;
    }
}
