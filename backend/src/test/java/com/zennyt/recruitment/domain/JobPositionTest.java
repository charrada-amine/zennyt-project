package com.zennyt.recruitment.domain;

import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JobPositionTest {

    @Test
    void proposeCreatesPendingPositionWithoutProfileType() {
        JobPosition position = JobPosition.propose("Développeur Rust", "IT, AI & Fintech", UUID.randomUUID(), null, null);

        assertThat(position.status()).isEqualTo(JobPositionStatus.PENDING_APPROVAL);
        assertThat(position.profileType()).isNull();
        assertThat(position.calibrated()).isFalse();
    }

    @Test
    void blankNameRejected() {
        assertThatThrownBy(() -> JobPosition.propose("  ", null, UUID.randomUUID(), null, null))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void approveAssignsProfileTypeAndStatus() {
        JobPosition position = JobPosition.propose("Développeur Rust", null, UUID.randomUUID(), null, null);

        position.approve(JobProfileType.TECHNIQUE);

        assertThat(position.status()).isEqualTo(JobPositionStatus.APPROVED);
        assertThat(position.profileType()).isEqualTo(JobProfileType.TECHNIQUE);
    }

    @Test
    void cannotApproveTwice() {
        JobPosition position = JobPosition.propose("Développeur Rust", null, UUID.randomUUID(), null, null);
        position.approve(JobProfileType.TECHNIQUE);

        assertThatThrownBy(() -> position.approve(JobProfileType.TECHNIQUE))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void rejectMarksPositionRejected() {
        JobPosition position = JobPosition.propose("Développeur Rust", null, UUID.randomUUID(), null, null);

        position.reject();

        assertThat(position.status()).isEqualTo(JobPositionStatus.REJECTED);
    }

    @Test
    void levelLabelFallsBackToDefaultWhenNoOverride() {
        JobPosition position = JobPosition.rehydrate(UUID.randomUUID(), "Développeur", "IT, AI & Fintech",
            JobProfileType.TECHNIQUE, false, JobPositionStatus.APPROVED, null,
            null, null, null, null, Instant.now(), null, null);

        assertThat(position.levelLabel(ExperienceLevel.JUNIOR)).isEqualTo("Junior");
        assertThat(position.levelLabel(ExperienceLevel.SENIOR)).isEqualTo("Senior");
        assertThat(position.levelLabel(ExperienceLevel.LEAD)).isEqualTo("Lead");
        assertThat(position.levelLabel(ExperienceLevel.MANAGER)).isEqualTo("Manager");
    }

    @Test
    void levelLabelUsesCustomOverrideWhenPresent() {
        JobPosition position = JobPosition.rehydrate(UUID.randomUUID(), "Ouvrier / Compagnon qualifié",
            "Construction & Infrastructure", JobProfileType.TECHNIQUE, false, JobPositionStatus.APPROVED, null,
            "Apprenti / Ouvrier débutant", "Compagnon confirmé", "Chef d'équipe", "Chef de chantier", Instant.now(),
            null, null);

        assertThat(position.levelLabel(ExperienceLevel.JUNIOR)).isEqualTo("Apprenti / Ouvrier débutant");
        assertThat(position.levelLabel(ExperienceLevel.MANAGER)).isEqualTo("Chef de chantier");
    }
}
