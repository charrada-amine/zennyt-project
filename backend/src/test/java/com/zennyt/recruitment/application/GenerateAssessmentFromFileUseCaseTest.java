package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.application.port.SourceDocumentExtractorPort;
import com.zennyt.recruitment.application.usecase.GenerateAssessmentFromFileUseCase;
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

class GenerateAssessmentFromFileUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();
    private static final byte[] FAKE_PDF_BYTES = "%PDF-1.4 fake content".getBytes();

    private AssessmentGeneratorPort generator;
    private SourceDocumentExtractorPort extractor;
    private AssessmentRepository repository;
    private GenerateAssessmentFromFileUseCase useCase;

    @BeforeEach
    void setUp() {
        generator = mock(AssessmentGeneratorPort.class);
        extractor = mock(SourceDocumentExtractorPort.class);
        repository = mock(AssessmentRepository.class);
        useCase = new GenerateAssessmentFromFileUseCase(generator, extractor, repository);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(extractor.extractText(any())).thenReturn("extracted source text");
    }

    private static List<AssessmentQuestion> questions(int count) {
        return java.util.stream.IntStream.range(0, count)
            .mapToObj(i -> new AssessmentQuestion("Q" + i, List.of("A", "B", "C", "D"), 0))
            .toList();
    }

    @Test
    void generatesAndPersistsAssessmentFromFile() {
        when(generator.generate(any())).thenReturn(questions(3));

        Assessment result = useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(FAKE_PDF_BYTES, "Quizz number 1.pdf", 3));

        assertThat(result.createdByRecruiterId()).isEqualTo(RECRUITER);
        assertThat(result.generationSource()).isEqualTo(AssessmentGenerationMode.FROM_FILE);
        assertThat(result.title()).isEqualTo("Quizz number 1");
        assertThat(result.questions()).hasSize(3);
        assertThat(result.shareableLink()).isNotBlank();
    }

    @Test
    void emptyFileRejected() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(new byte[0], "file.pdf", 3)))
            .isInstanceOf(IllegalArgumentException.class);
        verify(extractor, never()).extractText(any());
    }

    @Test
    void fileOver5MbRejected() {
        byte[] tooLarge = new byte[6 * 1024 * 1024];
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(tooLarge, "file.pdf", 3)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void questionCountOutOfBoundsRejected() {
        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(FAKE_PDF_BYTES, "file.pdf", 31)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void extractorRejectionPropagates() {
        when(extractor.extractText(any())).thenThrow(new IllegalArgumentException("Seul le format PDF est supporté pour le moment"));

        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(FAKE_PDF_BYTES, "file.txt", 3)))
            .isInstanceOf(IllegalArgumentException.class);
        verify(generator, never()).generate(any());
    }

    @Test
    void emptyAiOutputMapsToUpstreamServiceException() {
        when(generator.generate(any())).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.execute(RECRUITER,
            new GenerateAssessmentFromFileUseCase.Command(FAKE_PDF_BYTES, "file.pdf", 3)))
            .isInstanceOf(UpstreamServiceException.class);
        verify(repository, never()).save(any());
    }
}
