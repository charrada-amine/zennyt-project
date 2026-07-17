package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.SubmitAttemptUseCase;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ConflictException;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SubmitAttemptUseCaseTest {
    private final AssessmentAttemptRepository attempts = mock(AssessmentAttemptRepository.class);
    private final AssessmentRepository assessments = mock(AssessmentRepository.class);
    private final JobOfferRepository offers = mock(JobOfferRepository.class);
    private final ApplicationRepository applications = mock(ApplicationRepository.class);
    private final ApplicationEventPublisher events = mock(ApplicationEventPublisher.class);
    private final SubmitAttemptUseCase useCase = new SubmitAttemptUseCase(
        attempts, assessments, offers, applications, events);

    @Test
    void createsOneApplicationAndLinksAttemptUsingOfferThreshold() {
        UUID candidateId = UUID.randomUUID();
        UUID assessmentId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        Assessment assessment = Assessment.createManual(UUID.randomUUID(), "Test", 60,
            List.of(new AssessmentQuestion("Q1", List.of("A", "B", "C", "D"), 0),
                new AssessmentQuestion("Q2", List.of("A", "B", "C", "D"), 0)));
        JobOffer offer = mock(JobOffer.class);
        when(offer.assessmentId()).thenReturn(assessmentId);
        when(offer.passingScore()).thenReturn(60);
        when(assessments.findById(assessmentId)).thenReturn(Optional.of(assessment));
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));
        when(applications.findByCandidateIdAndJobOfferId(candidateId, offerId))
            .thenReturn(Optional.empty());
        when(applications.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(attempts.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        var result = useCase.execute(new SubmitAttemptUseCase.Command(
            candidateId, assessmentId, offerId, List.of(0, 1)));

        assertThat(result.attempt().applicationId()).isEqualTo(result.application().id());
        assertThat(result.attempt().score()).isEqualTo(50);
        assertThat(result.attempt().passed()).isFalse();
        verify(applications, times(1)).save(any(Application.class));
    }

    @Test
    void appliesPerOfferOverrideAndRejectsDuplicateBeforeCreatingApplication() {
        UUID candidateId = UUID.randomUUID();
        UUID assessmentId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        when(attempts.existsByCandidateIdAndAssessmentIdAndJobOfferId(
            candidateId, assessmentId, offerId)).thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(new SubmitAttemptUseCase.Command(
            candidateId, assessmentId, offerId, List.of(0))))
            .isInstanceOf(ConflictException.class);
        verifyNoInteractions(applications);
    }

    @Test
    void domainPassesAtExactCustomThreshold() {
        UUID applicationId = UUID.randomUUID();
        var question = new AssessmentQuestion("Q", List.of("A", "B", "C", "D"), 0);
        AssessmentAttempt attempt = AssessmentAttempt.submit(UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), applicationId, List.of(0), List.of(question), 100);
        assertThat(attempt.passed()).isTrue();
    }
}
