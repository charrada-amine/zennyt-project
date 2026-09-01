package com.zennyt.games.domain.model;

import com.zennyt.games.domain.model.AdminModels.ConfigurationKind;
import com.zennyt.games.domain.vo.GameType;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AdminConfigurationSchemaRegistryTest {
    @Test
    void exposesSettingsAndModifiersForEveryGameType() {
        assertThat(AdminConfigurationSchemaRegistry.all()).hasSize(GameType.values().length * 2);
        for (GameType gameType : GameType.values()) {
            assertThat(AdminConfigurationSchemaRegistry.schema(
                gameType.name(), ConfigurationKind.SETTINGS).fields()).isNotEmpty();
            assertThat(AdminConfigurationSchemaRegistry.schema(
                gameType.name(), ConfigurationKind.MODIFIERS).fields()).isNotEmpty();
        }
    }

    @Test
    void validatesEmotionalRadarDefaults() {
        var settings = AdminConfigurationSchemaRegistry.schema(
            "EMOTIONAL_REGULATION", ConfigurationKind.SETTINGS).defaultValues();
        var modifiers = AdminConfigurationSchemaRegistry.schema(
            "EMOTIONAL_REGULATION", ConfigurationKind.MODIFIERS).defaultValues();

        AdminConfigurationSchemaRegistry.validate(
            "EMOTIONAL_REGULATION", ConfigurationKind.SETTINGS, settings);
        AdminConfigurationSchemaRegistry.validate(
            "EMOTIONAL_REGULATION", ConfigurationKind.MODIFIERS, modifiers);

        assertThat(settings).containsEntry("sceneCount", 3)
            .containsEntry("orderMode", "SEQUENTIAL")
            .containsEntry("sessionEnabled", true);
        assertThat(modifiers).containsEntry("reducedMotionDefault", false)
            .containsEntry("answerFeedback", true)
            .containsEntry("transitionDurationMs", 900);
    }

    @Test
    void rejectsUnknownProtectedOrMistypedControls() {
        assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate(
            "MOVE_FAST", ConfigurationKind.SETTINGS,
            Map.of("sessionEnabled", true, "scoreMultiplier", 4)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("scoreMultiplier");

        assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate(
            "EMOTIONAL_REGULATION", ConfigurationKind.SETTINGS,
            Map.of("sessionEnabled", true, "sceneCount", 16,
                "orderMode", "SEQUENTIAL", "helpEnabled", true)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("sceneCount");

        assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate(
            "PLANIFIK", ConfigurationKind.MODIFIERS,
            Map.of("reducedMotionDefault", "false")))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("reducedMotionDefault");
    }
}
