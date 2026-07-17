package com.zennyt.recruitment.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.recruitment.application.usecase.ResolvePublicTestUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PublicTestControllerTest {
    @Test
    void publicProjectionNeverContainsCorrectOptionIndex() throws Exception {
        ResolvePublicTestUseCase useCase = mock(ResolvePublicTestUseCase.class);
        Assessment assessment = Assessment.createManual(java.util.UUID.randomUUID(), "Test", 60,
            List.of(new AssessmentQuestion("Question", List.of("A", "B", "C", "D"), 2)));
        when(useCase.execute(assessment.id().toString())).thenReturn(assessment);

        var response = new PublicTestController(useCase)
            .getByToken(assessment.id().toString()).getBody();
        String json = new ObjectMapper().writeValueAsString(response);

        assertThat(json).contains("Question", "A", "B");
        assertThat(json).doesNotContain("correctOptionIndex");
    }
}
