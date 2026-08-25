package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.vo.DifficultyLevel;
import com.zennyt.games.domain.vo.EmotionDefinition;
import com.zennyt.games.domain.vo.RadarV2SceneAssignment;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.security.SecureRandom;
import java.util.Set;
import java.util.UUID;

/** Fabrique des 15 affectations d'une session Radar V2. */
public final class EmotionalRadarV2SceneFactory {

    private final EmotionReferential referential;
    private final SemanticDistanceModel distanceModel;
    private final DistractorSelectionService distractors;
    private final Random serverRandom;

    public EmotionalRadarV2SceneFactory(EmotionReferential referential,
                                        SemanticDistanceModel distanceModel) {
        this(referential, distanceModel, new SecureRandom());
    }

    /** Constructeur à graine contrôlée réservé aux tests du package. */
    EmotionalRadarV2SceneFactory(EmotionReferential referential,
                                 SemanticDistanceModel distanceModel,
                                 Random serverRandom) {
        this.referential = referential;
        this.distanceModel = distanceModel;
        this.distractors = new DistractorSelectionService(referential, distanceModel);
        if (serverRandom == null) {
            throw new IllegalArgumentException("générateur serveur requis");
        }
        this.serverRandom = serverRandom;
    }

    /**
     * Crée une scène sans média tant que la banque 45 × 3 n'est pas livrée.
     *
     * <p>L'UUID public de session n'alimente jamais le tirage. La cible, l'ordre
     * des choix et l'intensité viennent d'un CSPRNG serveur. Les cibles déjà
     * persistées sont exclues pour garantir 15 émotions distinctes ; le verrou
     * de ligne de {@code GameSession} sérialise cet appel en production.
     */
    public RadarV2SceneAssignment create(UUID sessionId, int sceneOrder,
                                         int levelNumber,
                                         Set<String> excludedTargetKeys,
                                         Instant servedAt) {
        if (referential.size() != EmotionalRadarV2Config.EMOTION_POOL_SIZE) {
            throw new IllegalStateException("référentiel V2 attendu à 45 émotions");
        }
        DifficultyLevel level = EmotionalRadarV2Config.level(levelNumber);
        Set<String> excluded = excludedTargetKeys == null
            ? Set.of() : Set.copyOf(excludedTargetKeys);
        List<EmotionDefinition> available = new ArrayList<>(referential.all());
        available.removeIf(emotion -> excluded.contains(emotion.key()));
        if (available.isEmpty()) {
            throw new IllegalStateException("plus aucune émotion cible disponible");
        }
        if (available.size() < level.choicesCount()) {
            throw new IllegalStateException("pas assez d'émotions cibles encore disponibles");
        }

        /*
         * PHASE A PLACEHOLDER : tirer d'abord l'ensemble public, puis la cible
         * secrète à l'intérieur. Chaque choix visible reste ainsi équiprobable,
         * même si le client connaît l'algorithme et toutes les anciennes cibles.
         * La sélection par strate/distance ne sera réactivée qu'avec des stimuli
         * normés et un protocole serveur non reconstructible.
         */
        Collections.shuffle(available, serverRandom);
        List<EmotionDefinition> choices = new ArrayList<>(
            available.subList(0, level.choicesCount()));
        EmotionDefinition correct = choices.get(serverRandom.nextInt(choices.size()));
        double sceneDifficulty = distractors.sceneDifficulty(correct, choices);
        int intensity = serverRandom.nextInt(
            EmotionalRadarV2Config.STIMULUS_INTENSITY_LEVELS.size());

        return RadarV2SceneAssignment.pending(
            sessionId, sceneOrder, levelNumber,
            choices.stream().map(EmotionDefinition::key).toList(),
            sceneDifficulty, correct.key(), correct.stimulusType(), intensity,
            correct.sensitiveContentFlag(), servedAt);
    }
}
