package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.EmotionalRadarV2Config;
import com.zennyt.games.infrastructure.catalog.JsonEmotionReferential;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Random;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class EmotionalRadarV2SceneFactoryTest {

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
            PUBLIC_SESSION_ID, 1, 1, Set.of(), Instant.EPOCH);
        var b = secretStreamB.create(
            PUBLIC_SESSION_ID, 1, 1, Set.of(), Instant.EPOCH);

        assertThat(a.correctEmotionKey()).isNotEqualTo(b.correctEmotionKey());
        assertThat(a.choiceKeys()).isNotEqualTo(b.choiceKeys());
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
            PUBLIC_SESSION_ID, 1, 1, Set.of(), Instant.EPOCH);
        var b = targetAtSecondPublicChoice.create(
            PUBLIC_SESSION_ID, 1, 1, Set.of(), Instant.EPOCH);

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
