package com.zennyt.games.api.dto;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.games.domain.service.BartScoringService;
import com.zennyt.games.domain.service.IstScoringService;
import com.zennyt.games.domain.vo.BartBalloonOutcome;
import com.zennyt.games.domain.vo.BartMetrics;
import com.zennyt.games.domain.vo.IstColor;
import com.zennyt.games.domain.vo.IstMetrics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static com.zennyt.games.support.DecisionBehavioralTestFixtures.SESSION_ID;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.bartFixedStrategy;
import static com.zennyt.games.support.DecisionBehavioralTestFixtures.istStrategy;
import static org.assertj.core.api.Assertions.assertThat;

class DecisionBehavioralApiContractTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    @DisplayName("BART : la requête porte des pompes brutes ; point d'éclatement et score sont ignorés")
    void bartRequestCarriesRawPumpsOnly() throws Exception {
        String json = """
            {
              "miniGame": "BART_CORE",
              "metrics": {
                "protocolVersion": "BART_LEJUEZ_V1",
                "bartBalloons": [{
                  "balloonIndex": 0,
                  "phase": "PRACTICE",
                  "pumpCount": 2,
                  "outcome": "COLLECTED",
                  "pumpTimestampsMs": [180, 390],
                  "collectTimestampMs": 700,
                  "explosionPoint": 999
                }],
                "sessionCompleted": false,
                "interrupted": true,
                "backgroundEventCount": 0,
                "focusLossCount": 0,
                "score": 100
              }
            }
            """;

        SubmitResultRequest request = new ObjectMapper()
            .configure(com.fasterxml.jackson.databind.DeserializationFeature
                .FAIL_ON_UNKNOWN_PROPERTIES, false)
            .readValue(json, SubmitResultRequest.class);
        BartMetrics metrics = (BartMetrics) request.toMetrics();

        assertThat(metrics.balloons()).hasSize(1);
        assertThat(metrics.balloons().get(0).outcome()).isEqualTo(BartBalloonOutcome.COLLECTED);
        assertThat(metrics.balloons().get(0).pumpTimestampsMs()).containsExactly(180L, 390L);
    }

    @Test
    @DisplayName("IST : la requête porte les cases ouvertes et la décision, jamais les couleurs révélées")
    void istRequestCarriesOpeningsOnly() throws Exception {
        String json = """
            {
              "miniGame": "INFORMATION_SAMPLING_CORE",
              "metrics": {
                "protocolVersion": "IST_CLARK_V1",
                "istTrials": [{
                  "trialIndex": 0,
                  "phase": "PRACTICE",
                  "condition": "FIXED_WIN",
                  "openings": [{"boxIndex": 12, "timestampMs": 400},
                               {"boxIndex": 3, "timestampMs": 900}],
                  "chosenColor": "BLUE",
                  "decisionTimestampMs": 1500,
                  "confidence": 3
                }],
                "sessionCompleted": false,
                "interrupted": true,
                "backgroundEventCount": 0,
                "focusLossCount": 0
              }
            }
            """;

        IstMetrics metrics = (IstMetrics) mapper.readValue(json, SubmitResultRequest.class).toMetrics();

        assertThat(metrics.trials().get(0).openings()).hasSize(2);
        assertThat(metrics.trials().get(0).chosenColor()).isEqualTo(IstColor.BLUE);
        assertThat(metrics.trials().get(0).confidence()).isEqualTo(3);
        JsonNode trial = mapper.readTree(json).path("metrics").path("istTrials").get(0);
        assertThat(trial.path("openings").get(0).has("color")).isFalse();
    }

    @Test
    @DisplayName("Réponses : clés du contrat, sans sensibilité métacognitive")
    void responsesSerializeContractKeys() {
        var bart = GameSessionResponse.BartIndicatorsResponse.from(
            new BartScoringService().report(SESSION_ID, bartFixedStrategy(SESSION_ID, 64, 200)));
        var ist = GameSessionResponse.IstIndicatorsResponse.from(
            new IstScoringService().report(SESSION_ID, istStrategy(SESSION_ID, 25, 15, 4, false, 300)));

        JsonNode bartJson = mapper.valueToTree(bart);
        JsonNode istJson = mapper.valueToTree(ist);

        assertThat(bartJson.path("efficiencyPercent").asInt()).isEqualTo(100);
        assertThat(bartJson.path("optimalFixedPumps").asInt()).isEqualTo(64);
        assertThat(bartJson.has("adjustedAveragePumps")).isTrue();
        assertThat(istJson.has("calibrationBias")).isTrue();
        assertThat(istJson.has("auroc2")).isFalse();
        assertThat(istJson.has("metaDPrime")).isFalse();
    }
}
