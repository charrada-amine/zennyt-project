package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class TestResultRecomputeListenerTest {
    private final JobOfferRepository offers = mock(JobOfferRepository.class);
    private final FitScoreRecomputeWorker worker = mock(FitScoreRecomputeWorker.class);
    private final TestResultRecomputeListener listener = new TestResultRecomputeListener(offers, worker);

    @Test
    void submitsRecomputeForTheOfferTheTestWasTakenOn() {
        UUID candidateId = UUID.randomUUID();
        UUID jobOfferId = UUID.randomUUID();
        JobOffer offer = mock(JobOffer.class);
        when(offers.findById(jobOfferId)).thenReturn(Optional.of(offer));
        var event = TestResultCompletedEvent.of(UUID.randomUUID(), candidateId, UUID.randomUUID(),
            jobOfferId, 82, true);

        listener.on(event);

        verify(worker).submit(argThat((RecomputeFitScoresUseCase.Pair pair) ->
            pair.candidateId().equals(candidateId) && pair.offer() == offer));
    }

    @Test
    void neverSubmitsWhenTheOfferNoLongerExists() {
        UUID jobOfferId = UUID.randomUUID();
        when(offers.findById(jobOfferId)).thenReturn(Optional.empty());
        var event = TestResultCompletedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            jobOfferId, 82, true);

        listener.on(event);

        verify(worker, never()).submit(any());
    }
}
