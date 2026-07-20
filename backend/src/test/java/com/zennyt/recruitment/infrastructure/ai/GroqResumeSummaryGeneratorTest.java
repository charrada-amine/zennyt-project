package com.zennyt.recruitment.infrastructure.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GroqResumeSummaryGeneratorTest {
    private final GroqResumeSummaryGenerator generator = new GroqResumeSummaryGenerator(
        new ObjectMapper(), "key", "model", 100, 100);

    @Test
    void parsesFencedBilingualJson() {
        String response = """
            {"choices":[{"message":{"content":"```json\\n{\\"fr\\":\\"texte fr\\",\\"en\\":\\"text en\\"}\\n```"}}]}
            """;

        var result = generator.parseBilingualText(response);

        assertThat(result.fr()).isEqualTo("texte fr");
        assertThat(result.en()).isEqualTo("text en");
    }

    @Test
    void missingLanguageRejected() {
        String response = """
            {"choices":[{"message":{"content":"{\\"fr\\":\\"texte fr\\"}"}}]}
            """;

        assertThatThrownBy(() -> generator.parseBilingualText(response))
            .isInstanceOf(UpstreamServiceException.class);
    }

    @Test
    void noChoicesRejected() {
        assertThatThrownBy(() -> generator.parseBilingualText("{\"choices\":[]}"))
            .isInstanceOf(UpstreamServiceException.class);
    }
}
