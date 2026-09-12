package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.catalog.StrategicChoicesCatalog;
import com.zennyt.games.domain.vo.StrategicChoiceStrategy;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Banque « Choix Stratégiques » adossée à la ressource livrée.
 *
 * <p>{@code resources/games/strategic_choices_bank.json} est engendré depuis le
 * document du client par {@code tooling/games/convert-strategic-choices-bank.py},
 * qui écrit la MÊME ressource côté mobile. Une seule source, deux copies : un
 * écran et un barème qui divergeraient ne parleraient plus de la même situation.
 *
 * <p>Seules la cotation et le drapeau de validation servent ici ; les textes
 * (contexte, scène, justifications) documentent la banque et sont exploités par
 * l'écran, pas par le moteur.
 */
@Component
public class JsonStrategicChoicesCatalog implements StrategicChoicesCatalog {

    private static final String RESOURCE_PATH = "games/strategic_choices_bank.json";

    private final Map<String, Situation> situationsById;

    public JsonStrategicChoicesCatalog() {
        this.situationsById = load(RESOURCE_PATH);
    }

    private static Map<String, Situation> load(String path) {
        ObjectMapper mapper = new ObjectMapper();
        try (InputStream stream = new ClassPathResource(path).getInputStream()) {
            Bank bank = mapper.readValue(stream, Bank.class);
            Map<String, Situation> byId = new LinkedHashMap<>();
            for (RawSituation raw : bank.situations()) {
                Map<StrategicChoiceStrategy, Integer> scores =
                    new EnumMap<>(StrategicChoiceStrategy.class);
                for (RawChoice choice : raw.choices()) {
                    StrategicChoiceStrategy strategy =
                        StrategicChoiceStrategy.valueOf(choice.strategy());
                    if (choice.score() < 0
                        || choice.score() > 3) {
                        throw new IllegalStateException(
                            raw.id() + " : cotation hors 0-3 — " + choice.score());
                    }
                    scores.put(strategy, choice.score());
                }
                if (scores.size() != StrategicChoiceStrategy.values().length) {
                    throw new IllegalStateException(
                        raw.id() + " : les huit stratégies ne sont pas toutes cotées");
                }
                byId.put(raw.id(), new Situation(
                    scores,
                    scores.values().stream().mapToInt(Integer::intValue).max().orElse(0),
                    scores.values().stream().mapToInt(Integer::intValue).average().orElse(0),
                    raw.needsPsychologistValidation()));
            }
            if (byId.isEmpty()) {
                throw new IllegalStateException("Banque Choix Stratégiques vide : " + path);
            }
            return Map.copyOf(byId);
        } catch (IOException error) {
            throw new IllegalStateException(
                "Banque Choix Stratégiques illisible : " + path, error);
        }
    }

    @Override
    public Set<String> situationIds() {
        return situationsById.keySet();
    }

    @Override
    public int score(String situationId, StrategicChoiceStrategy strategy) {
        return require(situationId).scores().get(strategy);
    }

    @Override
    public int bestScore(String situationId) {
        return require(situationId).bestScore();
    }

    @Override
    public double chanceBaseline(String situationId) {
        return require(situationId).chanceBaseline();
    }

    @Override
    public boolean needsPsychologistValidation(String situationId) {
        return require(situationId).needsValidation();
    }

    private Situation require(String situationId) {
        Situation situation = situationsById.get(situationId);
        if (situation == null) {
            throw new IllegalArgumentException(
                "Situation Choix Stratégiques inconnue : " + situationId);
        }
        return situation;
    }

    private record Situation(
        Map<StrategicChoiceStrategy, Integer> scores,
        int bestScore,
        double chanceBaseline,
        boolean needsValidation
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Bank(List<RawSituation> situations) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record RawSituation(
        String id,
        boolean needsPsychologistValidation,
        List<RawChoice> choices
    ) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record RawChoice(String strategy, int score) {}
}
