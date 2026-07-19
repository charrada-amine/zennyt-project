package com.zennyt.recruitment.api;

import com.zennyt.recruitment.application.usecase.ChangeJobOfferStatusUseCase;
import com.zennyt.recruitment.application.usecase.CreateJobOfferUseCase;
import com.zennyt.recruitment.application.usecase.UpdateJobOfferUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class JobOfferPublicAccessTest {
    private final JobOfferRepository repository = mock(JobOfferRepository.class);
    private final JobOfferController controller = new JobOfferController(
        mock(CreateJobOfferUseCase.class), mock(UpdateJobOfferUseCase.class),
        mock(ChangeJobOfferStatusUseCase.class), repository,
        mock(com.zennyt.recruitment.domain.repository.ApplicationRepository.class),
        mock(com.zennyt.recruitment.domain.repository.AssessmentRepository.class),
        mock(com.zennyt.recruitment.domain.repository.FitScoreRepository.class),
        mock(com.zennyt.recruitment.application.usecase.GetSwipeDeckUseCase.class),
        mock(com.zennyt.recruitment.domain.repository.RecruitmentActorRepository.class));

    @Test
    void publicDetailHidesEveryNonActiveOffer() {
        for (JobOfferStatus status : new JobOfferStatus[]{
                JobOfferStatus.DRAFT, JobOfferStatus.HIDDEN, JobOfferStatus.CLOSED}) {
            UUID id = UUID.randomUUID();
            JobOffer offer = mock(JobOffer.class);
            when(offer.status()).thenReturn(status);
            when(repository.findById(id)).thenReturn(Optional.of(offer));
            assertThat(controller.getById(id, null).getStatusCode().value()).isEqualTo(404);
        }
    }
}
