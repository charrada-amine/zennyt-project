package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.catalog.DecisionScenarioCatalog;
import com.zennyt.games.domain.vo.DecisionDimension;
import com.zennyt.games.domain.vo.DecisionItemFormat;
import com.zennyt.games.domain.vo.OptionQuality;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Implémentation vivante du catalogue « Je Décide », adossée à la banque du
 * psychologue livrée en ressource ({@code resources/games/decision_scenarios.json}).
 *
 * <p><b>Contenu autoritaire côté serveur.</b> Pour chaque item, seul le triplet
 * (dimension, format, {@link OptionQuality} par {@code optionId}) sert au barème :
 * le client n'envoie jamais de qualité ni de score, uniquement {@code itemId} +
 * {@code optionId}. Les textes (vignette, énoncés d'options) présents dans la
 * ressource ne sont pas exploités par le moteur — ils documentent le contenu et
 * pourront être exposés au client par un lot ultérieur.
 *
 * <p>La banque compte 120 items (24 par dimension) permettant de tirer 4 formes
 * de 30 items. <b>Notation :</b> II et DT sont notés réellement (barème 0..3 /
 * réponse optimale du document) ; ER-19..24 également ; ER-1..18, RE et CS sont en
 * notation <b>neutre provisoire</b> ({@code SATISFACTORY} sur chaque option,
 * {@code provisionalScoring:true}) en attendant l'implémentation du vrai modèle de
 * profil (aversion λ, actualisation hyperbolique k, cohérence de paire). Remplacer
 * ce provisoire se fera en ré-étiquetant la ressource et/ou en enrichissant le
 * moteur — aucune donnée n'est inventée ici.
 *
 * <p><b>⚠️ Remplacée par {@link DatabaseDecisionScenarioCatalog} (V59).</b> La
 * banque vit désormais en base : c'est le seul moyen de SERVIR les vignettes et
 * les énoncés d'options au client, que ce chargeur laisse tomber. La classe est
 * conservée une release comme filet de secours et pour les tests hors base — elle
 * n'est plus un bean Spring. Le JSON, lui, reste la source du seed Flyway.
 */
@Deprecated(since = "V59", forRemoval = true)
public class JsonDecisionScenarioCatalog implements DecisionScenarioCatalog {

    private static final String RESOURCE_PATH = "games/decision_scenarios.json";

    private final Map<String, Item> itemsById;

    public JsonDecisionScenarioCatalog() {
        this.itemsById = load(RESOURCE_PATH);
    }

    private static Map<String, Item> load(String path) {
        ObjectMapper mapper = new ObjectMapper();
        Bank bank;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            bank = mapper.readValue(in, Bank.class);
        } catch (IOException e) {
            throw new IllegalStateException(
                "Impossible de charger la banque « Je Décide » : " + path, e);
        }
        if (bank.items() == null || bank.items().isEmpty()) {
            throw new IllegalStateException("Banque « Je Décide » vide : " + path);
        }
        Map<String, Item> byId = new LinkedHashMap<>();
        for (ItemJson raw : bank.items()) {
            Map<String, OptionQuality> qualities = new LinkedHashMap<>();
            for (OptionJson opt : raw.options()) {
                qualities.put(opt.optionId(), OptionQuality.valueOf(opt.quality()));
            }
            Item item = new Item(
                raw.itemId(),
                DecisionDimension.valueOf(raw.dimension()),
                DecisionItemFormat.valueOf(raw.format()),
                raw.provisionalScoring() != null && raw.provisionalScoring(),
                qualities);
            if (byId.putIfAbsent(item.itemId(), item) != null) {
                throw new IllegalStateException(
                    "Item « Je Décide » en double dans la banque : " + item.itemId());
            }
        }
        return Map.copyOf(byId);
    }

    @Override
    public Optional<Item> item(String itemId) {
        return Optional.ofNullable(itemsById.get(itemId));
    }

    @Override
    public boolean isEmpty() {
        return itemsById.isEmpty();
    }

    /** Nombre d'items chargés (diagnostic / tests). */
    public int size() {
        return itemsById.size();
    }

    // ── Miroir JSON de la ressource (seuls les champs utiles sont lus) ────────

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Bank(List<ItemJson> items) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record ItemJson(String itemId, String dimension, String format,
                            Boolean provisionalScoring, List<OptionJson> options) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record OptionJson(String optionId, String quality) {
    }
}
