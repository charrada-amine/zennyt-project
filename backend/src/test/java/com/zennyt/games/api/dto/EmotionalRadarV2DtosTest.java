package com.zennyt.games.api.dto;

import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.AnswerRequest;
import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.ReportResponse;
import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.SceneResponse;
import com.zennyt.games.api.dto.EmotionalRadarV2Dtos.StateResponse;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;

import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

class EmotionalRadarV2DtosTest {

    @Test
    void playerSceneExposesServerRemainingBudgetWithoutClockOrSensitiveMetadata() {
        var fields = Arrays.stream(SceneResponse.class.getRecordComponents())
            .map(component -> component.getName())
            .toList();

        assertThat(fields).contains("remainingResponseTimeMs");
        assertThat(fields).doesNotContain(
            "servedAt", "sensitiveContentFlag", "correctEmotionKey",
            "stimulusIntensity", "sceneDifficulty", "stimulusType",
            "targetDistanceBand");
    }

    @Test
    void playerReportNeverExposesInternalThetaEstimate() {
        var fields = Arrays.stream(ReportResponse.class.getRecordComponents())
            .map(component -> component.getName())
            .toList();

        assertThat(fields).doesNotContain(
            "theta", "standardError", "reliabilityFlag", "decisionalUseAllowed");
    }

    @Test
    void playerStateCarriesUniversalPhaseAMeasurementGate() {
        var fields = Arrays.stream(StateResponse.class.getRecordComponents())
            .map(component -> component.getName())
            .toList();

        assertThat(fields).contains("measurementAvailable");
    }

    @Test
    void selectedEmotionKeyIsCappedAtSixtyFourCharacters() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var violations = factory.getValidator().validate(
                new AnswerRequest("X".repeat(65), 1, "Explication brute."));

            assertThat(violations)
                .extracting(violation -> violation.getPropertyPath().toString())
                .containsExactly("selectedEmotionKey");
        }
    }
}
