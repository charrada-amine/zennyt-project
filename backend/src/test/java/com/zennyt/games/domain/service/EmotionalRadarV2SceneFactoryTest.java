package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.domain.config.EmotionalRadarV2ProvisionalRules;
import com.zennyt.games.domain.vo.RadarMediaStatus;
import com.zennyt.games.infrastructure.catalog.JsonEmotionReferential;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Random;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class EmotionalRadarV2SceneFactoryTest {

    /**
     * Première scène dont la cible est réellement TIRÉE AU SORT.
     *
     * <p>En démonstration, {@code DEMO_FOOTAGE_FIRST} impose l'émotion des
     * scènes 1 à 3 — celles qui ont une vidéo. Les propriétés d'équiprobabilité
     * vérifiées ici ne valent donc qu'au-delà.
     */
    private static final int FREE_DRAW_SCENE_ORDER =
        EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_ORDER.size() + 1;

    private static final UUID PUBLIC_SESSION_ID =
        UUID.fromString("00000000-0000-4000-8000-000000000042");

    @Test
    void publicSessionUuidDoesNotDetermineTargetChoicesOrIntensity() {
        var referential = new JsonEmotionReferential();
        var distance = new ValenceArousalDistanceModel();
        var secretStreamA = new EmotionalRadarV2SceneFactory(
            referential, distance, new Random(1L));
        var secretStreamB = new EmotionalRadarV2SceneFactory(
            referential, distance, new Random(2L));

        var a = secretStreamA.create(
            PUBLIC_SESSION_ID, FREE_DRAW_SCENE_ORDER, 1, Set.of(), Instant.EPOCH);
        var b = secretStreamB.create(
            PUBLIC_SESSION_ID, FREE_DRAW_SCENE_ORDER, 1, Set.of(), Instant.EPOCH);

        assertThat(a.correctEmotionKey()).isNotEqualTo(b.correctEmotionKey());
        assertThat(a.choiceKeys()).isNotEqualTo(b.choiceKeys());
    }

    /**
     * Les 3 clips produits sont attachés à l'émotion qu'ils représentent, jamais
     * à un numéro de scène. Rattacher par ordre — ce que faisait la v1 — mettrait
     * une femme inquiète en face d'une réponse attendue « Joie ».
     */
    @Test
    void footageFollowsTheTargetEmotionRatherThanTheSceneOrder() {
        var referential = new JsonEmotionReferential();
        var distance = new ValenceArousalDistanceModel();

        // Balayage large : on cherche, pour chaque cible rencontrée, la cohérence
        // entre présence de clip et statut média — sans dépendre d'un tirage.
        boolean sawReady = false;
        boolean sawPlaceholder = false;
        for (long seed = 0; seed < 200; seed++) {
            var factory = new EmotionalRadarV2SceneFactory(
                referential, distance, new Random(seed));
            // Au-delà des scènes de démonstration imposées : ici la cible est
            // bien tirée au sort, donc les deux cas se présentent.
            int sceneOrder = EmotionalRadarV2ProvisionalRules
                .DEMO_FOOTAGE_ORDER.size() + 1;
            var scene = factory.create(
                PUBLIC_SESSION_ID, sceneOrder, 1, Set.of(), Instant.EPOCH);
            var footage = EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE
                .get(scene.correctEmotionKey());

            if (footage == null) {
                assertThat(scene.mediaStatus())
                    .as("cible %s sans clip", scene.correctEmotionKey())
                    .isEqualTo(RadarMediaStatus.PLACEHOLDER_PENDING);
                assertThat(scene.mediaUrl()).isNull();
                sawPlaceholder = true;
            } else {
                assertThat(scene.mediaStatus())
                    .as("cible %s avec clip", scene.correctEmotionKey())
                    .isEqualTo(RadarMediaStatus.READY);
                assertThat(scene.mediaUrl()).isEqualTo(footage.mediaUrl());
                sawReady = true;
            }
        }

        assertThat(sawReady)
            .as("aucune des 3 émotions filmées n'est sortie en 200 tirages")
            .isTrue();
        assertThat(sawPlaceholder).isTrue();
    }

    /**
     * En démonstration, les trois premières scènes visent les émotions filmées —
     * dans l'ordre annoncé, et quelle que soit la graine du tirage.
     */
    @Test
    void demoModePutsFilmedEmotionsFirst() {
        var referential = new JsonEmotionReferential();
        var distance = new ValenceArousalDistanceModel();
        var order = EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_ORDER;

        for (long seed = 0; seed < 25; seed++) {
            var factory = new EmotionalRadarV2SceneFactory(
                referential, distance, new Random(seed));
            for (int sceneOrder = 1; sceneOrder <= order.size(); sceneOrder++) {
                var scene = factory.create(
                    PUBLIC_SESSION_ID, sceneOrder, 1, Set.of(), Instant.EPOCH);
                assertThat(scene.correctEmotionKey())
                    .as("graine %d, scène %d", seed, sceneOrder)
                    .isEqualTo(order.get(sceneOrder - 1));
                assertThat(scene.mediaStatus()).isEqualTo(RadarMediaStatus.READY);
                // La cible est imposée, sa POSITION dans la grille ne l'est pas.
                assertThat(scene.choiceKeys()).contains(scene.correctEmotionKey());
            }
        }
    }

    /** Une émotion déjà tirée ne revient pas, même en mode démonstration. */
    @Test
    void demoModeNeverRepeatsAnAlreadyUsedTarget() {
        var referential = new JsonEmotionReferential();
        var distance = new ValenceArousalDistanceModel();
        var factory = new EmotionalRadarV2SceneFactory(
            referential, distance, new Random(7L));
        String first = EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE_ORDER.get(0);

        var scene = factory.create(
            PUBLIC_SESSION_ID, 1, 1, Set.of(first), Instant.EPOCH);

        assertThat(scene.correctEmotionKey())
            .as("les 15 cibles doivent rester distinctes : cette règle prime")
            .isNotEqualTo(first);
    }

    /** Un stimulus contextuel servi avec sa vidéo doit porter sa légende. */
    @Test
    void contextualFootageCarriesItsCaption() {
        var referential = new JsonEmotionReferential();
        EmotionalRadarV2ProvisionalRules.DEMO_FOOTAGE.forEach((key, footage) -> {
            var emotion = referential.byKey(key)
                .orElseThrow(() -> new AssertionError(
                    key + " absente du référentiel des 45"));
            if (emotion.stimulusType().requiresContextualCaption()) {
                assertThat(footage.contextualCaption())
                    .as("%s est contextuelle : légende requise", key)
                    .isNotBlank();
            }
        });
    }

    @Test
    void identicalPublicChoiceSetCanCorrespondToDifferentSecretTargets() {
        var referential = new JsonEmotionReferential();
        var distance = new ValenceArousalDistanceModel();
        var targetAtFirstPublicChoice = new EmotionalRadarV2SceneFactory(
            referential, distance, new FixedPublicSetRandom(0));
        var targetAtSecondPublicChoice = new EmotionalRadarV2SceneFactory(
            referential, distance, new FixedPublicSetRandom(1));

        var a = targetAtFirstPublicChoice.create(
            PUBLIC_SESSION_ID, FREE_DRAW_SCENE_ORDER, 1, Set.of(), Instant.EPOCH);
        var b = targetAtSecondPublicChoice.create(
            PUBLIC_SESSION_ID, FREE_DRAW_SCENE_ORDER, 1, Set.of(), Instant.EPOCH);

        assertThat(a.choiceKeys()).isEqualTo(b.choiceKeys());
        assertThat(a.correctEmotionKey()).isEqualTo(a.choiceKeys().get(0));
        assertThat(b.correctEmotionKey()).isEqualTo(b.choiceKeys().get(1));
        assertThat(a.correctEmotionKey()).isNotEqualTo(b.correctEmotionKey());
    }

    /**
     * Collections.shuffle(45) consomme 44 tirages ; le 45e choisit la cible
     * dans l'ensemble public déjà figé.
     */
    private static final class FixedPublicSetRandom extends Random {
        private final int secretTargetIndex;
        private int boundedCalls;

        private FixedPublicSetRandom(int secretTargetIndex) {
            this.secretTargetIndex = secretTargetIndex;
        }

        @Override
        public int nextInt(int bound) {
            boundedCalls++;
            if (boundedCalls == EmotionalRadarV2Config.EMOTION_POOL_SIZE) {
                return secretTargetIndex;
            }
            return 0;
        }
    }
}
