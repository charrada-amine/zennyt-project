package com.zennyt.recruitment.application;

import com.zennyt.games.domain.event.GameResultRecordedEvent;
import com.zennyt.games.domain.vo.GameType;
import com.zennyt.recruitment.application.usecase.GenerateSoftSkillsSummaryUseCase;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class GameSoftSkillsListenerTest {

    @Test
    void anOlderAsyncEventCannotTriggerARegressionOrARecalculation() {
        SoftSkillsProjectionRepository projections = mock(SoftSkillsProjectionRepository.class);
        RecomputeFitScoresUseCase recompute = mock(RecomputeFitScoresUseCase.class);
        FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
        GenerateSoftSkillsSummaryUseCase summary = mock(GenerateSoftSkillsSummaryUseCase.class);
        when(projections.saveIfNotOlder(any())).thenReturn(false);
        GameSoftSkillsListener listener =
            new GameSoftSkillsListener(projections, recompute, enqueuer, summary);
        UUID candidateId = UUID.randomUUID();

        listener.on(event(candidateId, 33, Instant.parse("2026-08-13T10:15:30Z")));

        verify(recompute, never()).pairsForCandidate(any());
        verify(enqueuer, never()).enqueueUrgent(any());
        verify(summary, never()).execute(any());
    }

    @Test
    void anAppliedEventStillQueuesFitAndRegeneratesTheSummary() {
        SoftSkillsProjectionRepository projections = mock(SoftSkillsProjectionRepository.class);
        RecomputeFitScoresUseCase recompute = mock(RecomputeFitScoresUseCase.class);
        FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
        GenerateSoftSkillsSummaryUseCase summary = mock(GenerateSoftSkillsSummaryUseCase.class);
        when(projections.saveIfNotOlder(any())).thenReturn(true);
        when(recompute.pairsForCandidate(any())).thenReturn(List.of());
        GameSoftSkillsListener listener =
            new GameSoftSkillsListener(projections, recompute, enqueuer, summary);
        UUID candidateId = UUID.randomUUID();

        listener.on(event(candidateId, 100, Instant.parse("2026-08-13T10:16:30Z")));

        verify(recompute).pairsForCandidate(candidateId);
        verify(enqueuer).enqueueUrgent(List.of());
        verify(summary).execute(candidateId);
    }

    private static GameResultRecordedEvent event(UUID candidateId, int coverage, Instant occurredAt) {
        return new GameResultRecordedEvent(
            UUID.randomUUID(), occurredAt, UUID.randomUUID(), candidateId,
            GameType.PLANIFIK, 24, 30, 80, coverage, "AVANCE");
    }
}
