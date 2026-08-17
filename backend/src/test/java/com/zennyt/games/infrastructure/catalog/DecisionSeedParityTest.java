package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Non-régression du passage de la banque « Je Décide » du JSON vers la base (V59).
 *
 * <p>Le score d'un item ne dépend que de trois choses : sa dimension, son format et
 * la {@code OptionQuality} de l'option choisie. Si le seed SQL porte exactement le
 * même triplet que la ressource JSON, alors <b>aucun score ne peut changer</b> —
 * quel que soit le catalogue branché. C'est ce que vérifie ce test, sans base :
 * il compare la source du seed au SQL généré.
 *
 * <p>Les cardinalités (120 items, 24 par dimension, 66 provisoires, paires CS
 * complètes, composition de la forme A) sont vérifiées par le bloc {@code DO $$} de
 * la migration elle-même : elles échouent au déploiement, pas ici.
 */
class DecisionSeedParityTest {

    private static final String JSON = "games/decision_scenarios.json";
    private static final String SQL = "db/migration/V59__games_decision_scenarios.sql";

    /** `('uuid', 'II-1', 'II', 'STANDARD', …` — en-tête d'une ligne de scénario. */
    private static final Pattern SCENARIO_ROW = Pattern.compile(
        "\\('[0-9a-f-]{36}', '([^']+)', '(II|ER|DT|CS|RE)', "
            + "'(STANDARD|TEMPORAL_DECISION|COHERENCE_PAIR)', ");

    /** `('uuid', 'uuid', 'II-1-o1', $t$…$t$, 'OPTIMAL', 1)` — ligne d'option. */
    private static final Pattern OPTION_ROW = Pattern.compile(
        "\\('[0-9a-f-]{36}', '[0-9a-f-]{36}', '([^']+)', \\$t\\$.*?\\$t\\$, "
            + "'(OPTIMAL|SATISFACTORY|PARTIAL|DEFICIENT)', \\d+\\)",
        Pattern.DOTALL);

    private static String read(String path) throws IOException {
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @Test
    @DisplayName("le seed SQL porte les mêmes dimensions et formats que la banque JSON")
    void scenarioMetadataMatchesBank() throws Exception {
        Map<String, String> fromJson = new LinkedHashMap<>();
        for (JsonNode item : new ObjectMapper().readTree(read(JSON)).get("items")) {
            fromJson.put(item.get("itemId").asText(),
                item.get("dimension").asText() + '/' + item.get("format").asText());
        }

        Map<String, String> fromSql = new LinkedHashMap<>();
        Matcher m = SCENARIO_ROW.matcher(read(SQL));
        while (m.find()) {
            fromSql.put(m.group(1), m.group(2) + '/' + m.group(3));
        }

        assertEquals(120, fromJson.size(), "La banque JSON n'a plus 120 items.");
        assertEquals(fromJson, fromSql,
            "Le seed SQL a divergé de la banque JSON : régénérer V59 depuis le JSON.");
    }

    @Test
    @DisplayName("le seed SQL porte la même clé de correction que la banque JSON")
    void optionQualitiesMatchBank() throws Exception {
        Map<String, String> fromJson = new LinkedHashMap<>();
        for (JsonNode item : new ObjectMapper().readTree(read(JSON)).get("items")) {
            for (JsonNode option : item.get("options")) {
                fromJson.put(option.get("optionId").asText(), option.get("quality").asText());
            }
        }

        Map<String, String> fromSql = new LinkedHashMap<>();
        Matcher m = OPTION_ROW.matcher(read(SQL));
        while (m.find()) {
            fromSql.put(m.group(1), m.group(2));
        }

        assertEquals(324, fromJson.size(), "La banque JSON n'a plus 324 options.");
        assertEquals(fromJson, fromSql,
            "Une qualité d'option a changé entre le JSON et le seed SQL : "
                + "le passage en base modifierait les scores.");
    }
}
