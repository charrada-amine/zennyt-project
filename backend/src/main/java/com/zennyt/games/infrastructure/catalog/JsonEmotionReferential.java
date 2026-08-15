package com.zennyt.games.infrastructure.catalog;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.vo.EmotionCategory;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.StimulusType;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Référentiel émotionnel « Emotional Radar v2 » adossé à la ressource
 * {@code resources/games/emotional_radar_emotions.json} (45 émotions).
 *
 * <p>Contenu <b>PROVISOIRE</b> : base Cowen &amp; Keltner + compléments, coordonnées
 * sémantiques placeholder. À figer par le psychologue sans changement de code.
 */
@Component
public class JsonEmotionReferential implements EmotionReferential {

    private static final String RESOURCE_PATH = "games/emotional_radar_emotions.json";

    private final List<EmotionDefinition> emotions;
    private final Map<String, EmotionDefinition> byKey;

    public JsonEmotionReferential() {
        this.emotions = load(RESOURCE_PATH);
        Map<String, EmotionDefinition> index = new LinkedHashMap<>();
        for (EmotionDefinition e : emotions) {
            if (index.putIfAbsent(e.key(), e) != null) {
                throw new IllegalStateException("Émotion en double dans le référentiel : " + e.key());
            }
        }
        this.byKey = Map.copyOf(index);
    }

    private static List<EmotionDefinition> load(String path) {
        ObjectMapper mapper = new ObjectMapper();
        Bank bank;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            bank = mapper.readValue(in, Bank.class);
        } catch (IOException e) {
            throw new IllegalStateException("Impossible de charger le référentiel émotionnel : " + path, e);
        }
        if (bank.emotions() == null || bank.emotions().isEmpty()) {
            throw new IllegalStateException("Référentiel émotionnel vide : " + path);
        }
        List<EmotionDefinition> out = new ArrayList<>();
        for (EmotionJson e : bank.emotions()) {
            out.add(new EmotionDefinition(
                e.key(), e.labelFr(), e.labelEn(),
                EmotionCategory.valueOf(e.category()),
                StimulusType.valueOf(e.stimulusType()),
                e.valence(), e.arousal()));
        }
        return List.copyOf(out);
    }

    @Override
    public List<EmotionDefinition> all() {
        return emotions;
    }

    @Override
    public Optional<EmotionDefinition> byKey(String key) {
        return Optional.ofNullable(key == null ? null : byKey.get(key.trim()));
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Bank(List<EmotionJson> emotions) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record EmotionJson(String key, String labelFr, String labelEn,
                               String category, String stimulusType,
                               double valence, double arousal) {
    }
}
