package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class GroqFitScoreCalculatorTest {
    private final GroqFitScoreCalculator calculator = new GroqFitScoreCalculator(
        new ObjectMapper(), "key", "model", 100, 100);

    @Test
    void parsesFencedJsonAndBoundsEveryScore() {
        String response = """
            {"choices":[{"message":{"content":"```json\\n{\\\"score\\\":120,\\\"softSkillScore\\\":-4,\\\"cvMatchScore\\\":81}\\n```"}}]}
            """;

        var result = calculator.parseResponse(response);

        assertThat(result.score()).isEqualTo(100);
        assertThat(result.softSkillScore()).isZero();
        assertThat(result.cvMatchScore()).isEqualTo(81);
    }
}
