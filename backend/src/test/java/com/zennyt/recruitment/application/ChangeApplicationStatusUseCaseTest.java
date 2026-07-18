package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.ChangeApplicationStatusUseCase;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ChangeApplicationStatusUseCaseTest {
    @Test
    void publishes_enriched_status_event_after_save() {
        var applications = mock(ApplicationRepository.class);
        var offers = mock(JobOfferRepository.class);
        var publisher = mock(ApplicationEventPublisher.class);
        UUID applicationId = UUID.randomUUID(), candidateId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID(), recruiterId = UUID.randomUUID();
        Application application = Application.rehydrate(applicationId, candidateId, offerId,
            ApplicationStatus.PENDING, Instant.now(), Instant.now());
        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(recruiterId);
        when(offer.title()).thenReturn("Backend Engineer");
        when(applications.findById(applicationId)).thenReturn(Optional.of(application));
        when(applications.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));

        new ChangeApplicationStatusUseCase(applications, offers, publisher)
            .execute(applicationId, recruiterId, ApplicationStatus.SHORTLISTED);

        var event = org.mockito.ArgumentCaptor.forClass(ApplicationStatusChangedEvent.class);
        verify(publisher).publishEvent(event.capture());
        assertThat(event.getValue().previousStatus()).isEqualTo(ApplicationStatus.PENDING);
        assertThat(event.getValue().newStatus()).isEqualTo(ApplicationStatus.SHORTLISTED);
        assertThat(event.getValue().recruiterId()).isEqualTo(recruiterId);
        assertThat(event.getValue().jobTitle()).isEqualTo("Backend Engineer");
    }
}
