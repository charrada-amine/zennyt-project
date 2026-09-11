package com.zennyt.games.domain.service;

import com.zennyt.games.domain.catalog.EmotionReferential;
import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.config.EmotionalRadarV2ProvisionalRules;
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
     * Crée une scène : avec sa vidéo si l'émotion tirée fait partie des 3 clips
     * déjà produits, sans média sinon, tant que la banque 45 × 3 n'est pas livrée.
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

        /*
         * DÉMO : les trois premières scènes visent les émotions qui ont une
         * vidéo, pour qu'une démonstration les montre à coup sûr. Piloté par
         * EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_FIRST — une fois la
         * banque livrée, le drapeau retombe et le tirage redevient uniforme.
         *
         * La POSITION de la bonne réponse dans la grille reste tirée au sort :
         * forcer la cible ne doit pas la rendre repérable à l'œil.
         */
        EmotionDefinition forced = forcedTarget(sceneOrder, available);
        List<EmotionDefinition> choices;
        EmotionDefinition correct;
        if (forced == null) {
            choices = new ArrayList<>(available.subList(0, level.choicesCount()));
            correct = choices.get(serverRandom.nextInt(choices.size()));
        } else {
            choices = new ArrayList<>(level.choicesCount());
            for (EmotionDefinition candidate : available) {
                if (choices.size() == level.choicesCount() - 1) break;
                if (!candidate.key().equals(forced.key())) choices.add(candidate);
            }
            choices.add(forced);
            Collections.shuffle(choices, serverRandom);
            correct = forced;
        }
        double sceneDifficulty = distractors.sceneDifficulty(correct, choices);
        int intensity = serverRandom.nextInt(
            EmotionalRadarV2Config.STIMULUS_INTENSITY_LEVELS.size());

        List<String> choiceKeys = choices.stream().map(EmotionDefinition::key).toList();

        /*
         * Les 3 seuls clips produits à ce jour sont rattachés à l'émotion qu'ils
         * représentent réellement, jamais à un numéro de scène : une vidéo qui
         * contredit la correction serait pire qu'un placeholder. Le rattachement
         * est fait ICI parce que le client ignore la cible — et doit continuer
         * à l'ignorer.
         */
        EmotionalRadarV2ProvisionalRules.DemoFootage footage =
            EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE.get(correct.key());
        if (footage != null) {
            return RadarV2SceneAssignment.ready(
                sessionId, sceneOrder, levelNumber, choiceKeys,
                sceneDifficulty, correct.key(), correct.stimulusType(), intensity,
                correct.sensitiveContentFlag(), servedAt,
                footage.mediaUrl(), footage.contextualCaption());
        }

        return RadarV2SceneAssignment.pending(
            sessionId, sceneOrder, levelNumber, choiceKeys,
            sceneDifficulty, correct.key(), correct.stimulusType(), intensity,
            correct.sensitiveContentFlag(), servedAt);
    }

    /**
     * Émotion imposée pour cette scène en mode démonstration, {@code null} sinon.
     *
     * <p>Rend la main si l'émotion a déjà été tirée dans la session : les 15
     * cibles doivent rester distinctes, cette règle passe avant la démo.
     */
    private EmotionDefinition forcedTarget(int sceneOrder,
                                           List<EmotionDefinition> available) {
        if (!EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_FIRST) return null;
        List<String> order = EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_ORDER;
        if (sceneOrder < 1 || sceneOrder > order.size()) return null;
        String key = order.get(sceneOrder - 1);
        return available.stream()
            .filter(emotion -> emotion.key().equals(key))
            .findFirst()
            .orElse(null);
    }
}
