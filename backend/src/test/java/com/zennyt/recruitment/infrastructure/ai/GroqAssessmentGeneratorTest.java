package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GroqAssessmentGeneratorTest {
    private final GroqAssessmentGenerator generator = new GroqAssessmentGenerator(
        new ObjectMapper(), "key", "model", 100, 100);

    @Test
    void parsesFencedJsonIntoValidQuestions() {
        String response = """
            {"choices":[{"message":{"content":"```json\\n{\\"questions\\":[{\\"text\\":\\"Q1\\",\\"options\\":[\\"A\\",\\"B\\",\\"C\\",\\"D\\"],\\"correctOptionIndex\\":2}]}\\n```"}}]}
            """;

        var result = generator.parseQuestions(response, 1);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).text()).isEqualTo("Q1");
        assertThat(result.get(0).correctOptionIndex()).isEqualTo(2);
    }

    @Test
    void invalidOptionCountRejected() {
        String response = """
            {"choices":[{"message":{"content":"{\\"questions\\":[{\\"text\\":\\"Q1\\",\\"options\\":[\\"A\\",\\"B\\"],\\"correctOptionIndex\\":0}]}"}}]}
            """;

        assertThatThrownBy(() -> generator.parseQuestions(response, 1))
            .isInstanceOf(UpstreamServiceException.class);
    }

    @Test
    void noChoicesRejected() {
        assertThatThrownBy(() -> generator.parseQuestions("{\"choices\":[]}", 1))
            .isInstanceOf(UpstreamServiceException.class);
    }
}
