package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.GetSwipeDeckUseCase;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class GetSwipeDeckUseCaseTest {
    @Test
    void recruiterDeckPreservesScoreOrderAndExcludesDismissedPairs() {
        UUID recruiterId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        UUID firstCandidate = UUID.randomUUID();
        UUID dismissedCandidate = UUID.randomUUID();
        JobOfferRepository offers = mock(JobOfferRepository.class);
        FitScoreRepository scores = mock(FitScoreRepository.class);
        FitScoreDismissalRepository dismissals = mock(FitScoreDismissalRepository.class);
        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(recruiterId);
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));
        when(scores.findByJobOfferIdOrderByScoreDesc(offerId)).thenReturn(List.of(
            FitScore.calculated(UUID.randomUUID(), firstCandidate, offerId, 95, 90, null, 100, Instant.now()),
            FitScore.calculated(UUID.randomUUID(), dismissedCandidate, offerId, 80, 75, null, 100, Instant.now())));
        when(dismissals.isDismissed(recruiterId, dismissedCandidate, offerId)).thenReturn(true);

        var deck = new GetSwipeDeckUseCase(offers, scores, dismissals, mock(CandidateFeedRanker.class),
                mock(InlineFitScoreComputer.class), 200)
            .recruiterCandidates(recruiterId, offerId, 0, 20);

        assertThat(deck.totalElements()).isEqualTo(1);
        assertThat(deck.content()).extracting(FitScore::candidateId)
            .containsExactly(firstCandidate);
    }
}
