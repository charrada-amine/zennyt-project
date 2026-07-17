package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.GetOfferApplicationsUseCase;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class GetOfferApplicationsUseCaseTest {
    @Test
    void keepsFlaggedVisibleButExcludesItFromSuccessRate() {
        UUID recruiterId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        UUID candidateA = UUID.randomUUID();
        UUID candidateB = UUID.randomUUID();
        JobOfferRepository offers = mock(JobOfferRepository.class);
        ApplicationRepository applications = mock(ApplicationRepository.class);
        AssessmentAttemptRepository attempts = mock(AssessmentAttemptRepository.class);
        JobOffer offer = mock(JobOffer.class);
        when(offer.recruiterId()).thenReturn(recruiterId);
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));
        Application appA = Application.rehydrate(UUID.randomUUID(), candidateA, offerId,
            ApplicationStatus.PENDING, Instant.now(), Instant.now());
        Application appB = Application.rehydrate(UUID.randomUUID(), candidateB, offerId,
            ApplicationStatus.PENDING, Instant.now(), Instant.now());
        when(applications.findByJobOfferId(offerId, null, 0, 20)).thenReturn(List.of(appA, appB));
        when(applications.countByJobOfferId(offerId, null)).thenReturn(2L);
        when(attempts.findAllByJobOfferId(offerId)).thenReturn(List.of(
            attempt(candidateA, offerId, 80, true, IntegrityStatus.VALIDATED),
            attempt(candidateB, offerId, 90, true, IntegrityStatus.NOT_VALIDATED)));

        var result = new GetOfferApplicationsUseCase(offers, applications, attempts)
            .execute(offerId, recruiterId, null, 0, 20);

        assertThat(result.applications()).hasSize(2);
        assertThat(result.applications()).extracting(row -> row.bestAttempt().integrityStatus())
            .contains(IntegrityStatus.NOT_VALIDATED);
        assertThat(result.successRate()).isEqualTo(100.0);
        assertThat(result.applicantCount()).isEqualTo(2);
    }

    private AssessmentAttempt attempt(UUID candidateId, UUID offerId, int score,
                                      boolean passed, IntegrityStatus integrity) {
        return AssessmentAttempt.rehydrate(UUID.randomUUID(), UUID.randomUUID(), candidateId,
            offerId, UUID.randomUUID(), score, passed, true, integrity, Instant.now());
    }
}
