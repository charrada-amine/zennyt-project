package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.application.usecase.GenerateSoftSkillsSummaryUseCase;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GenerateSoftSkillsSummaryUseCaseTest {

    private static final UUID CANDIDATE = UUID.randomUUID();

    private SoftSkillsProjectionRepository projections;
    private ResumeSummaryGeneratorPort generator;
    private SoftSkillsSummaryRepository summaries;
    private GenerateSoftSkillsSummaryUseCase useCase;

    @BeforeEach
    void setUp() {
        projections = mock(SoftSkillsProjectionRepository.class);
        generator = mock(ResumeSummaryGeneratorPort.class);
        summaries = mock(SoftSkillsSummaryRepository.class);
        useCase = new GenerateSoftSkillsSummaryUseCase(projections, generator, summaries);
    }

    @Test
    void skipsGenerationWhenNoModulePlayedYet() {
        when(projections.findByCandidateId(CANDIDATE)).thenReturn(List.of());

        useCase.execute(CANDIDATE);

        verify(generator, never()).generateSoftSkillsSummary(any());
        verify(summaries, never()).save(any());
    }

    @Test
    void generatesAndPersistsFromPlayedModules() {
        when(projections.findByCandidateId(CANDIDATE)).thenReturn(List.of(
            SoftSkillsProjection.create(CANDIDATE, "MOVE_FAST", 82, Instant.now()),
            SoftSkillsProjection.create(CANDIDATE, "MEMORY_QUEST", 74, Instant.now())));
        when(generator.generateSoftSkillsSummary(any()))
            .thenReturn(new ResumeSummaryGeneratorPort.BilingualText("texte fr", "text en"));

        useCase.execute(CANDIDATE);

        @SuppressWarnings("unchecked")
        var captor = org.mockito.ArgumentCaptor.forClass(Map.class);
        verify(generator).generateSoftSkillsSummary(captor.capture());
        assertThat(captor.getValue()).containsEntry("Cognitive flexibility", 82)
            .containsEntry("Working memory", 74);

        var summaryCaptor = org.mockito.ArgumentCaptor.forClass(SoftSkillsSummary.class);
        verify(summaries).save(summaryCaptor.capture());
        assertThat(summaryCaptor.getValue().candidateId()).isEqualTo(CANDIDATE);
        assertThat(summaryCaptor.getValue().textFr()).isEqualTo("texte fr");
        assertThat(summaryCaptor.getValue().textEn()).isEqualTo("text en");
    }
}
