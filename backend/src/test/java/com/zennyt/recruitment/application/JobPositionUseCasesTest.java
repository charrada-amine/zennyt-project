package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.ProposeJobPositionUseCase;
import com.zennyt.recruitment.application.usecase.ReviewJobPositionUseCase;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class JobPositionUseCasesTest {

    private static final UUID RECRUITER = UUID.randomUUID();

    private JobPositionRepository positions;
    private ProposeJobPositionUseCase proposeUseCase;
    private ReviewJobPositionUseCase reviewUseCase;

    @BeforeEach
    void setUp() {
        positions = mock(JobPositionRepository.class);
        proposeUseCase = new ProposeJobPositionUseCase(positions);
        reviewUseCase = new ReviewJobPositionUseCase(positions);
        when(positions.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void proposeSavesPendingPosition() {
        JobPosition created = proposeUseCase.execute(RECRUITER, "Développeur Rust", "IT, AI & Fintech");

        assertThat(created.status()).isEqualTo(JobPositionStatus.PENDING_APPROVAL);
        assertThat(created.proposedByRecruiterId()).isEqualTo(RECRUITER);
        verify(positions).save(any());
    }

    @Test
    void proposeDuplicateNameAndSectorThrows() {
        when(positions.existsByNameAndSector("Développeur Rust", "IT, AI & Fintech")).thenReturn(true);

        assertThatThrownBy(() -> proposeUseCase.execute(RECRUITER, "Développeur Rust", "IT, AI & Fintech"))
            .isInstanceOf(ConflictException.class);
        verify(positions, never()).save(any());
    }

    @Test
    void approveUnknownPositionThrows() {
        UUID id = UUID.randomUUID();
        when(positions.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewUseCase.approve(id, JobProfileType.TECHNIQUE))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void approveExistingPendingPosition() {
        UUID id = UUID.randomUUID();
        JobPosition pending = JobPosition.propose("Développeur Rust", null, RECRUITER);
        when(positions.findById(id)).thenReturn(Optional.of(pending));

        JobPosition approved = reviewUseCase.approve(id, JobProfileType.TECHNIQUE);

        assertThat(approved.status()).isEqualTo(JobPositionStatus.APPROVED);
        assertThat(approved.profileType()).isEqualTo(JobProfileType.TECHNIQUE);
    }

    @Test
    void rejectExistingPendingPosition() {
        UUID id = UUID.randomUUID();
        JobPosition pending = JobPosition.propose("Développeur Rust", null, RECRUITER);
        when(positions.findById(id)).thenReturn(Optional.of(pending));

        JobPosition rejected = reviewUseCase.reject(id);

        assertThat(rejected.status()).isEqualTo(JobPositionStatus.REJECTED);
    }
}
