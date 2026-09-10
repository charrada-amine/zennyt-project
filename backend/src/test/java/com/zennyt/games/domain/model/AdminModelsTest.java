package com.zennyt.games.domain.model;

import com.zennyt.games.domain.model.AdminModels.Bank;
import com.zennyt.games.domain.model.AdminModels.Configuration;
import com.zennyt.games.domain.model.AdminModels.ConfigurationKind;
import com.zennyt.games.domain.model.AdminModels.ContentType;
import com.zennyt.games.domain.model.AdminModels.Status;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertEquals;

class AdminModelsTest {
    @Test
    void acceptsNonScoringExperienceConfiguration() {
        Configuration configuration = new Configuration(UUID.randomUUID(),
            "emotional_regulation", ConfigurationKind.SETTINGS, 1,
            "{\"sceneCount\":12,\"orderMode\":\"SHUFFLED\",\"helpEnabled\":true}",
            Status.DRAFT, Instant.EPOCH);

        assertEquals("EMOTIONAL_REGULATION", configuration.gameType());
    }

    @Test
    void rejectsProtectedScoringKeys() {
        assertThatThrownBy(() -> new Configuration(UUID.randomUUID(), "MOVE_FAST",
            ConfigurationKind.MODIFIERS, 1,
            "{\"scoreMultiplier\":50}", Status.DRAFT, Instant.EPOCH))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("scoring protégée");
    }

    @Test
    void rejectsRotationOutsidePercentageRange() {
        assertThatThrownBy(() -> new Bank(UUID.randomUUID(), "B", "Forme B",
            ContentType.DECISION_SCENARIO, 0, 101, 1, Status.DRAFT, Instant.EPOCH))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
