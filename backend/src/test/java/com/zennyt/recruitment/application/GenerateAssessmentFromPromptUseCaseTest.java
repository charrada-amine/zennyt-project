package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.application.usecase.GenerateAssessmentFromPromptUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.vo.AssessmentGenerationMode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GenerateAssessmentFromPromptUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();

    private AssessmentGeneratorPort generator;
    private AssessmentRepository repository;
    private GenerateAssessmentFromPromptUseCase useCase;

    @BeforeEach
    void setUp() {
        generator = mock(AssessmentGeneratorPort.class);
        repository = mock(AssessmentRepository.class);
        useCase = new GenerateAssessmentFromPromptUseCase(generator, repository);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    private static List<AssessmentQuestion> questions(int count) {
        return java.util.stream.IntStream.range(0, count)
            .mapToObj(i -> new AssessmentQuestion("Q" + i, List.of("A", "B", "C", "D"), 0))
            .toList();
    }

    @Test
    void generatesAndPersistsAssessmentFromPrompt() {
        when(generator.generate(any())).thenReturn(questions(5));

        Assessment result = useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command("Senior React developer, Redux, REST APIs", 5));

        assertThat(result.createdByRecruiterId()).isEqualTo(RECRUITER);
        assertThat(result.generationSource()).isEqualTo(AssessmentGenerationMode.FROM_PROMPT);
        assertThat(result.questions()).hasSize(5);
        assertThat(result.shareableLink()).isNotBlank();
    }

    @Test
    void blankDescriptionRejected() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command("   ", 5)))
            .isInstanceOf(IllegalArgumentException.class);
        verify(generator, never()).generate(any());
    }

    @Test
    void descriptionOver1000CharsRejected() {
        String tooLong = "a".repeat(1001);
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command(tooLong, 5)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void questionCountOutOfBoundsRejected() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command("valid description", 31)))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command("valid description", 0)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void emptyAiOutputMapsToUpstreamServiceException() {
        when(generator.generate(any())).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromPromptUseCase.Command("valid description", 5)))
            .isInstanceOf(UpstreamServiceException.class);
        verify(repository, never()).save(any());
    }
}
