package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.CancelHireUseCase;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOpportunityStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CancelHireUseCaseTest {

    private static final UUID RECRUITER = UUID.randomUUID();

    private final JobOpportunityOfferRepository offers = mock(JobOpportunityOfferRepository.class);
    private final org.springframework.context.ApplicationEventPublisher events =
        mock(org.springframework.context.ApplicationEventPublisher.class);
    private final CancelHireUseCase useCase = new CancelHireUseCase(offers, events);

    private JobOpportunityOffer confirmed(UUID recruiter, Instant respondedAt) {
        return JobOpportunityOffer.rehydrate(UUID.randomUUID(), recruiter, UUID.randomUUID(),
            UUID.randomUUID(), "UX/UI Designer", null, JobOpportunityStatus.CONFIRMED, true,
            respondedAt.minus(1, ChronoUnit.DAYS), respondedAt);
    }

    @Test
    void cancelsAHireStillWithinProbation() {
        JobOpportunityOffer offer = confirmed(RECRUITER, Instant.now().minus(10, ChronoUnit.DAYS));
        when(offers.findById(offer.id())).thenReturn(Optional.of(offer));
        when(offers.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        JobOpportunityOffer cancelled = useCase.execute(RECRUITER, offer.id());

        assertThat(cancelled.status()).isEqualTo(JobOpportunityStatus.CANCELLED);
        org.mockito.Mockito.verify(events).publishEvent(org.mockito.ArgumentMatchers.<Object>argThat(event ->
            event instanceof com.zennyt.recruitment.domain.event.JobOpportunityOfferCancelledEvent cancelledEvent
                && cancelledEvent.offerId().equals(offer.id())
                && cancelledEvent.recruiterId().equals(RECRUITER)
                && cancelledEvent.candidateId().equals(offer.candidateId())
                && cancelledEvent.jobOfferId().equals(offer.jobOfferId())
                && cancelledEvent.eventType().equals("recruitment.opportunity_offer.cancelled")));
    }

    @Test
    void refusesToCancelAfterProbationEnded() {
        JobOpportunityOffer offer = confirmed(RECRUITER, Instant.now().minus(120, ChronoUnit.DAYS));
        when(offers.findById(offer.id())).thenReturn(Optional.of(offer));

        assertThatThrownBy(() -> useCase.execute(RECRUITER, offer.id()))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void refusesAnotherRecruitersHire() {
        JobOpportunityOffer offer = confirmed(UUID.randomUUID(), Instant.now().minus(5, ChronoUnit.DAYS));
        when(offers.findById(offer.id())).thenReturn(Optional.of(offer));

        assertThatThrownBy(() -> useCase.execute(RECRUITER, offer.id()))
            .isInstanceOf(ForbiddenException.class);
    }
}
