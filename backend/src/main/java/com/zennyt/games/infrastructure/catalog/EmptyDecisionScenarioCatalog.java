package com.zennyt.games.infrastructure.catalog;

import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;

import java.util.Optional;

/**
 * Implémentation <b>VIDE</b> du catalogue « Je Décide » — repli / usage de test.
 *
 * <p><b>N'est plus le bean vivant</b> : depuis la livraison de la banque du
 * psychologue, l'implémentation active est {@link JsonDecisionScenarioCatalog}
 * (chargée depuis {@code resources/games/decision_scenarios.json}). Cette classe
 * reste disponible pour les tests qui veulent simuler un catalogue vide (mini-jeu
 * non jouable) sans démarrer le contexte Spring. Elle n'invente aucun scénario.
 */
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
