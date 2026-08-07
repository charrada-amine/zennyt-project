package com.zennyt.games.api.dto;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.service.ObjectLocationScoringService;
import com.zennyt.games.domain.vo.ObjectLocationMetrics;
import com.zennyt.games.support.ObjectLocationTestFixtures;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ObjectLocationApiContractTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void requestUsesObjectLocationLevelsAndNeverAcceptsLayoutOrScore() throws Exception {
        String json = """
            {
              "miniGame": "OBJECT_LOCATION_BINDING_CORE",
              "metrics": {
                "protocolVersion": "OBJECT_LOCATION_FINE_V1",
                "completionReason": "TECHNICAL_INTERRUPTION",
                "objectLocationLevels": [{
                  "phase": "PRACTICE",
                  "levelIndex": 0,
                  "objectCount": 2,
                  "actualEncodingDurationMs": 0,
                  "actualRetentionDurationMs": 0,
                  "actualRecallDurationMs": 0,
                  "timedOut": false,
                  "completed": false,
                  "actions": []
                }],
                "sessionCompleted": false,
                "interrupted": true,
                "backgroundEventCount": 0,
                "focusLossCount": 1,
                "orientationChangeCount": 0,
                "droppedFrameCount": 0
              }
            }
            """;

        SubmitResultRequest request = mapper.readValue(json, SubmitResultRequest.class);
        ObjectLocationMetrics metrics = assertInstanceOf(
            ObjectLocationMetrics.class, request.toMetrics());

        assertEquals(1, metrics.levels().size());
        assertEquals(1, metrics.focusLossCount());
        JsonNode raw = mapper.readTree(json).path("metrics");
        assertFalse(raw.has("generationSeed"));
        assertFalse(raw.has("originCellIndex"));
        assertFalse(raw.has("score"));
    }

    @Test
    void responseSerializesLevelIntervalWithTheContractKey() throws Exception {
        var metrics = ObjectLocationTestFixtures.perfect(
            ObjectLocationTestFixtures.SESSION_ID);
        var report = new ObjectLocationScoringService().report(
            ObjectLocationTestFixtures.SESSION_ID, metrics);
        var response = GameSessionResponse.ObjectLocationIndicatorsResponse.from(report);

        JsonNode json = mapper.valueToTree(response);

        assertEquals("OBJECT_LOCATION_FINE_V1", json.path("protocolVersion").asText());
        assertEquals(100, json.path("provisionalAccuracyScore").asInt());
        assertTrue(json.path("levels").get(0)
            .has("averageFirstPlacementIntervalMs"));
        assertTrue(json.has("averageFirstPlacementIntervalMs"));
    }
}
