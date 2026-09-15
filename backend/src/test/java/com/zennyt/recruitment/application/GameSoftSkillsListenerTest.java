package com.zennyt.recruitment.application;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.recruitment.application.usecase.GenerateSoftSkillsSummaryUseCase;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le listener projette le dernier score soft-skills par module puis enfile le
 * recalcul des paires et régénère le résumé. L'API de repository réellement
 * exposée est un {@code save} simple (une ligne par (candidat, module)) — les
 * anciennes assertions portaient sur un {@code saveIfNotOlder} absent du code
 * (voir la remédiation du build de tests).
 */
class GameSoftSkillsListenerTest {

    @Test
    void savesTheProjectionThenQueuesRecomputeAndRegeneratesTheSummary() {
        SoftSkillsProjectionRepository projections = mock(SoftSkillsProjectionRepository.class);
        RecomputeFitScoresUseCase recompute = mock(RecomputeFitScoresUseCase.class);
        FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
        GenerateSoftSkillsSummaryUseCase summary = mock(GenerateSoftSkillsSummaryUseCase.class);
        when(projections.findByCandidateIdAndModule(any(), any())).thenReturn(Optional.empty());
        when(recompute.pairsForCandidate(any())).thenReturn(List.of());
        GameSoftSkillsListener listener =
            new GameSoftSkillsListener(projections, recompute, enqueuer, summary);
        UUID candidateId = UUID.randomUUID();

        listener.on(event(candidateId, 100, Instant.parse("2026-08-13T10:16:30Z")));

        verify(projections).save(any());
        verify(recompute).pairsForCandidate(candidateId);
        verify(enqueuer).enqueueUrgent(List.of());
        verify(summary).execute(candidateId);
    }

    @Test
    void reusesTheExistingRowIdForTheSameModule() {
        SoftSkillsProjectionRepository projections = mock(SoftSkillsProjectionRepository.class);
        RecomputeFitScoresUseCase recompute = mock(RecomputeFitScoresUseCase.class);
        FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
        GenerateSoftSkillsSummaryUseCase summary = mock(GenerateSoftSkillsSummaryUseCase.class);
        UUID candidateId = UUID.randomUUID();
        UUID existingId = UUID.randomUUID();
        SoftSkillsProjection existing = new SoftSkillsProjection(
            existingId, candidateId, GameType.PLANIFIK.name(), 40, 50,
            Instant.parse("2026-08-13T09:00:00Z"));
        when(projections.findByCandidateIdAndModule(candidateId, GameType.PLANIFIK.name()))
            .thenReturn(Optional.of(existing));
        when(recompute.pairsForCandidate(any())).thenReturn(List.of());
        GameSoftSkillsListener listener =
            new GameSoftSkillsListener(projections, recompute, enqueuer, summary);

        listener.on(event(candidateId, 100, Instant.parse("2026-08-13T10:16:30Z")));

        var captor = org.mockito.ArgumentCaptor.forClass(SoftSkillsProjection.class);
        verify(projections).save(captor.capture());
        assertThat(captor.getValue().id()).isEqualTo(existingId);
        assertThat(captor.getValue().candidateId()).isEqualTo(candidateId);
        assertThat(captor.getValue().module()).isEqualTo(GameType.PLANIFIK.name());
    }

    @Test
    void createsANewRowWhenTheCandidateHasNoScoreForTheModuleYet() {
        SoftSkillsProjectionRepository projections = mock(SoftSkillsProjectionRepository.class);
        RecomputeFitScoresUseCase recompute = mock(RecomputeFitScoresUseCase.class);
        FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
        GenerateSoftSkillsSummaryUseCase summary = mock(GenerateSoftSkillsSummaryUseCase.class);
        when(projections.findByCandidateIdAndModule(any(), any())).thenReturn(Optional.empty());
        when(recompute.pairsForCandidate(any())).thenReturn(List.of());
        GameSoftSkillsListener listener =
            new GameSoftSkillsListener(projections, recompute, enqueuer, summary);
        UUID candidateId = UUID.randomUUID();

        listener.on(event(candidateId, 33, Instant.parse("2026-08-13T10:15:30Z")));

        var captor = org.mockito.ArgumentCaptor.forClass(SoftSkillsProjection.class);
        verify(projections).save(captor.capture());
        SoftSkillsProjection saved = captor.getValue();
        assertThat(saved.id()).isNotNull();
        assertThat(saved.module()).isEqualTo(GameType.PLANIFIK.name());
        assertThat(saved.coverageRatio()).isEqualTo(33);
    }

    private static GameResultRecordedEvent event(UUID candidateId, int coverage, Instant occurredAt) {
        return new GameResultRecordedEvent(
            UUID.randomUUID(), occurredAt, UUID.randomUUID(), candidateId,
            GameType.PLANIFIK, 24, 30, 80, coverage, "AVANCE");
    }
}
