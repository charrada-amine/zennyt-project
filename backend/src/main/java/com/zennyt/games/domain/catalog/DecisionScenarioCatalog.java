package com.zennyt.games.domain.catalog;

import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.OptionQuality;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Port (interface) — catalogue des scénarios « Je Décide ».
 *
 * <p>Le catalogue est le <b>seul dépositaire du contenu</b> : pour un item, il
 * fournit sa dimension, son format et la {@link OptionQuality} de chacune de ses
 * options. Le client n'envoie jamais de qualité ni de score : il transmet
 * l'{@code itemId} et l'{@code optionId} choisi ; le catalogue (côté serveur) fait
 * autorité sur la qualité.
 *
 * <p><b>⚠️ EN ATTENTE DU PSYCHOLOGUE.</b> L'implémentation vivante est un
 * placeholder <b>vide</b> ({@code EmptyDecisionScenarioCatalog}) : 30 scénarios +
 * étiquetage des options restent à fournir. Tant que le catalogue est vide,
 * {@code MiniGame.DECISION_CORE} n'est pas jouable (même patron que
 * {@code TASK_SCHEDULING} avant implémentation). Les tests injectent un catalogue
 * de test — aucun contenu de scénario n'est inventé dans le code de production.
 */
public interface DecisionScenarioCatalog {

    /**
     * Entrée d'un item : dimension, format et qualité de chaque option.
     *
     * @param provisionalScoring true → item en notation NEUTRE provisoire (toutes
     *        ses options à {@code SATISFACTORY}), en attendant le vrai modèle
     *        (aversion λ pour ER, actualisation hyperbolique k pour RE, cohérence
     *        de paire pour CS). Remonté dans le report pour que la lecture d'un
     *        score dise explicitement quelle dimension ne discrimine pas encore.
     */
    record Item(
        String itemId,
        DecisionDimension dimension,
        DecisionItemFormat format,
        boolean provisionalScoring,
        Map<String, OptionQuality> optionQualities
    ) {
        public Item {
            optionQualities = optionQualities == null ? Map.of() : Map.copyOf(optionQualities);
        }

        /** Qualité de l'option choisie ; erreur si l'option est inconnue de l'item. */
        public OptionQuality qualityOf(String optionId) {
            OptionQuality quality = optionQualities.get(optionId);
            if (quality == null) {
                throw new IllegalArgumentException(
                    "Option inconnue pour l'item " + itemId + " : " + optionId);
            }
            return quality;
        }
    }

    /** Métadonnées + qualités d'un item, ou {@code empty} si l'item est inconnu. */
    Optional<Item> item(String itemId);

    /** Session-bank-aware lookup; old catalogs keep their historical behavior. */
    default Optional<Item> item(String itemId, UUID bankId) {
        return item(itemId);
    }

    /** true si le catalogue ne contient aucun scénario (gate de jouabilité). */
    boolean isEmpty();
}
