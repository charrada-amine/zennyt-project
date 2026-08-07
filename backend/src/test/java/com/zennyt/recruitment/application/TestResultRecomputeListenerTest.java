package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.CandidateOfferPair;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

class TestResultRecomputeListenerTest {
    private final JobOfferRepository offers = mock(JobOfferRepository.class);
    private final FitScoreRecomputeWorker worker = mock(FitScoreRecomputeWorker.class);
    private final FitScoreEnqueuer enqueuer = mock(FitScoreEnqueuer.class);
    private final TestResultRecomputeListener listener =
        new TestResultRecomputeListener(offers, worker, enqueuer);

    private static final UUID POSITION_ID = UUID.randomUUID();

    @Test
    void submitsRecomputeForTheOfferTheTestWasTakenOn() {
        UUID candidateId = UUID.randomUUID();
        UUID jobOfferId = UUID.randomUUID();
        JobOffer offer = mock(JobOffer.class);
        when(offer.id()).thenReturn(jobOfferId);
        when(offer.jobPositionId()).thenReturn(POSITION_ID);
        when(offers.findById(jobOfferId)).thenReturn(Optional.of(offer));
        when(offers.findActiveIdsByJobPositionId(POSITION_ID)).thenReturn(List.of(jobOfferId));
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
        verify(enqueuer, never()).enqueueUrgent(anyList());
    }

    /**
     * D1 — le résultat compte désormais pour tout le métier : les autres offres ACTIVE du
     * même métier doivent être reprises, sinon leur score garde un sous-score hard devenu
     * faux. C'est le cœur du changement de portée de ce listener.
     */
    @Test
    void enqueuesTheOtherActiveOffersOfTheSameJobPosition() {
        UUID candidateId = UUID.randomUUID();
        UUID offreTestee = UUID.randomUUID();
        UUID soeurA = UUID.randomUUID();
        UUID soeurB = UUID.randomUUID();
        JobOffer offer = mock(JobOffer.class);
        when(offer.id()).thenReturn(offreTestee);
        when(offer.jobPositionId()).thenReturn(POSITION_ID);
        when(offers.findById(offreTestee)).thenReturn(Optional.of(offer));
        when(offers.findActiveIdsByJobPositionId(POSITION_ID))
            .thenReturn(List.of(offreTestee, soeurA, soeurB));
        var event = TestResultCompletedEvent.of(UUID.randomUUID(), candidateId, UUID.randomUUID(),
            offreTestee, 82, true);

        listener.on(event);

        @SuppressWarnings("unchecked")
        var captor = org.mockito.ArgumentCaptor.forClass(List.class);
        verify(enqueuer).enqueueUrgent(captor.capture());
        // L'offre testée n'est pas enfilée : elle est déjà partie en direct, l'enfiler
        // ferait recalculer deux fois la même paire.
        assertThat((List<CandidateOfferPair>) captor.getValue()).containsExactlyInAnyOrder(
            new CandidateOfferPair(candidateId, soeurA),
            new CandidateOfferPair(candidateId, soeurB));
    }

    /** Offre héritée sans métier : rien à propager, et surtout aucune exception. */
    @Test
    void offerWithoutJobPositionEnqueuesNothing() {
        UUID jobOfferId = UUID.randomUUID();
        JobOffer offer = mock(JobOffer.class);
        when(offer.id()).thenReturn(jobOfferId);
        when(offer.jobPositionId()).thenReturn(null);
        when(offers.findById(jobOfferId)).thenReturn(Optional.of(offer));
        var event = TestResultCompletedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            jobOfferId, 82, true);

        listener.on(event);

        verify(worker).submit(any());
        verify(enqueuer, never()).enqueueUrgent(anyList());
    }
}
