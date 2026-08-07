package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.event.JobOfferStatusChangedEvent;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ClosedJobOfferFitScorePurgerTest {

    private final FitScoreRepository fitScores = mock(FitScoreRepository.class);
    private final ClosedJobOfferFitScorePurger purger = new ClosedJobOfferFitScorePurger(fitScores);

    @Test
    void purgeLesScoresDUneOffreFermee() {
        UUID offerId = UUID.randomUUID();
        when(fitScores.deleteByJobOfferId(offerId)).thenReturn(12);

        purger.on(JobOfferStatusChangedEvent.of(offerId, JobOfferStatus.ACTIVE, JobOfferStatus.CLOSED));

        verify(fitScores).deleteByJobOfferId(offerId);
    }

    @Test
    void neTouchePasAuxScoresDUneOffreQuiDevientActive() {
        purger.on(JobOfferStatusChangedEvent.of(
            UUID.randomUUID(), JobOfferStatus.DRAFT, JobOfferStatus.ACTIVE));

        verify(fitScores, never()).deleteByJobOfferId(any());
    }

    @Test
    void neTouchePasAuxScoresDUneOffreQuiRepasseEnBrouillon() {
        purger.on(JobOfferStatusChangedEvent.of(
            UUID.randomUUID(), JobOfferStatus.ACTIVE, JobOfferStatus.DRAFT));

        verify(fitScores, never()).deleteByJobOfferId(any());
    }

    @Test
    void unePurgeEnEchecNInterromptPasLeTraitementDeLEvenement() {
        UUID offerId = UUID.randomUUID();
        when(fitScores.deleteByJobOfferId(offerId)).thenThrow(new IllegalStateException("base indisponible"));

        assertThatCode(() -> purger.on(
            JobOfferStatusChangedEvent.of(offerId, JobOfferStatus.ACTIVE, JobOfferStatus.CLOSED)))
            .doesNotThrowAnyException();
    }
}
