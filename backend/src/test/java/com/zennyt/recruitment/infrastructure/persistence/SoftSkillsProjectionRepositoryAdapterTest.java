package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SoftSkillsProjectionRepositoryAdapterTest {

    @Test
    void saveIfNotOlderDelegatesToTheAtomicConditionalUpsert() {
        JpaSoftSkillsProjectionRepository jpa = mock(JpaSoftSkillsProjectionRepository.class);
        SoftSkillsProjection projection = SoftSkillsProjection.create(
            UUID.randomUUID(), "PLANIFIK", 82, 100, Instant.parse("2026-08-13T10:15:30Z"));
        when(jpa.upsertIfNotOlder(
            projection.id(), projection.candidateId(), projection.module(), projection.score(),
            projection.coverageRatio(), projection.updatedAt())).thenReturn(1);

        boolean applied = new SoftSkillsProjectionRepositoryAdapter(jpa)
            .saveIfNotOlder(projection);

        assertThat(applied).isTrue();
        verify(jpa).upsertIfNotOlder(
            projection.id(), projection.candidateId(), projection.module(), projection.score(),
            projection.coverageRatio(), projection.updatedAt());
    }

    @Test
    void saveReturnsTheCurrentRowAfterTheAtomicUpsert() {
        JpaSoftSkillsProjectionRepository jpa = mock(JpaSoftSkillsProjectionRepository.class);
        UUID candidateId = UUID.randomUUID();
        SoftSkillsProjection projection = SoftSkillsProjection.create(
            candidateId, "PLANIFIK", 30, 33, Instant.parse("2026-08-13T10:15:30Z"));
        SoftSkillsProjectionEntity current = new SoftSkillsProjectionEntity(
            projection.id(), candidateId, "PLANIFIK", 30, 33, projection.updatedAt());
        when(jpa.upsertIfNotOlder(
            projection.id(), candidateId, "PLANIFIK", 30, 33, projection.updatedAt()))
            .thenReturn(1);
        when(jpa.findByCandidateIdAndModule(candidateId, "PLANIFIK"))
            .thenReturn(Optional.of(current));

        SoftSkillsProjection saved = new SoftSkillsProjectionRepositoryAdapter(jpa)
            .save(projection);

        assertThat(saved).isEqualTo(projection);
    }
}
