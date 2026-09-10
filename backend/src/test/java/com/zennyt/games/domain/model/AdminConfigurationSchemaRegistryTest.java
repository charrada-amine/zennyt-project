package com.zennyt.games.domain.model;

import com.zennyt.games.domain.model.AdminModels.ConfigurationKind;
import com.zennyt.games.domain.vo.GameType;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AdminConfigurationSchemaRegistryTest {
    @Test
    void materializesDefaultsAndOverridesIntoImmutableSessionValues() {
        var resolved = AdminConfigurationSchemaRegistry.effectiveValues("MEMORY_QUEST",
            ConfigurationKind.SETTINGS, Map.of("memoryDigitVisibleMs", 1800));
        assertThat(resolved).containsEntry("memoryDigitVisibleMs", 1800)
            .containsEntry("memoryDigitGapMs", 1000).containsEntry("sessionEnabled", true);
        assertThatThrownBy(() -> resolved.put("memoryDigitVisibleMs", 900))
            .isInstanceOf(UnsupportedOperationException.class);
    }
    @Test
    void validatesAllDefaultsAndPreservesLegacySettings() {
        for (var schema : AdminConfigurationSchemaRegistry.all()) {
            AdminConfigurationSchemaRegistry.validate(schema.gameType().name(), schema.kind(), schema.defaultValues());
        }
        AdminConfigurationSchemaRegistry.validate("MEMORY_QUEST", ConfigurationKind.SETTINGS, Map.of("sessionEnabled", true));
    }

    @Test
    void acceptsTimingOverridesButRejectsFractionsWrongGameAndUnsafeReflection() {
        AdminConfigurationSchemaRegistry.validate("MEMORY_QUEST", ConfigurationKind.SETTINGS,
            Map.of("sessionEnabled", true, "memoryDigitVisibleMs", 1500));
        for (Object invalid : new Object[] {299, 3001, 500.5, "900", Double.NaN, Double.POSITIVE_INFINITY}) {
            assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate("MEMORY_QUEST", ConfigurationKind.SETTINGS,
                Map.of("sessionEnabled", true, "memoryDigitVisibleMs", invalid)))
                .isInstanceOf(IllegalArgumentException.class);
        }
        assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate("PLANIFIK", ConfigurationKind.SETTINGS,
            Map.of("sessionEnabled", true, "memoryDigitVisibleMs", 900)))
            .isInstanceOf(IllegalArgumentException.class);
        var settings = new java.util.HashMap<>(AdminConfigurationSchemaRegistry.schema("EMOTIONAL_REGULATION", ConfigurationKind.SETTINGS).defaultValues());
        settings.put("reflectiveThinkingTimeMs", 2999);
        assertThatThrownBy(() -> AdminConfigurationSchemaRegistry.validate("EMOTIONAL_REGULATION", ConfigurationKind.SETTINGS, settings))
            .isInstanceOf(IllegalArgumentException.class);
    }

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
