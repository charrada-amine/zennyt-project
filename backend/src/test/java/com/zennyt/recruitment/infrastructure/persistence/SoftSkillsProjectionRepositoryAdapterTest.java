package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le repository applique un {@code save} simple (upsert JPA par identité) : une
 * ligne par (candidat, module), la plus récente écrite l'emportant. Ces tests
 * vérifient la délégation et le mapping domaine ⇄ entité sur l'API réellement
 * exposée — les anciennes assertions portaient sur un `saveIfNotOlder` qui
 * n'existe pas dans le code (voir la remédiation du build de tests).
 */
class SoftSkillsProjectionRepositoryAdapterTest {

    @Test
    void saveDelegatesToJpaSaveAndReturnsTheMappedRow() {
        JpaSoftSkillsProjectionRepository jpa = mock(JpaSoftSkillsProjectionRepository.class);
        UUID candidateId = UUID.randomUUID();
        SoftSkillsProjection projection = SoftSkillsProjection.create(
            candidateId, "PLANIFIK", 30, 33, Instant.parse("2026-08-13T10:15:30Z"));
        SoftSkillsProjectionEntity stored = new SoftSkillsProjectionEntity(
            projection.id(), candidateId, "PLANIFIK", 30, 33, projection.updatedAt());
        when(jpa.save(any())).thenReturn(stored);

        SoftSkillsProjection saved = new SoftSkillsProjectionRepositoryAdapter(jpa).save(projection);

        assertThat(saved).isEqualTo(projection);
        verify(jpa).save(any());
    }

    @Test
    void saveCarriesTheCandidateModuleScoreAndCoverageOntoTheEntity() {
        JpaSoftSkillsProjectionRepository jpa = mock(JpaSoftSkillsProjectionRepository.class);
        UUID candidateId = UUID.randomUUID();
        Instant updatedAt = Instant.parse("2026-08-13T10:15:30Z");
        SoftSkillsProjection projection = SoftSkillsProjection.create(
            candidateId, "MOVE_FAST", 82, 100, updatedAt);
        when(jpa.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        new SoftSkillsProjectionRepositoryAdapter(jpa).save(projection);

        var captor = org.mockito.ArgumentCaptor.forClass(SoftSkillsProjectionEntity.class);
        verify(jpa).save(captor.capture());
        SoftSkillsProjectionEntity entity = captor.getValue();
        assertThat(entity.getId()).isEqualTo(projection.id());
        assertThat(entity.getCandidateId()).isEqualTo(candidateId);
        assertThat(entity.getModule()).isEqualTo("MOVE_FAST");
        assertThat(entity.getScore()).isEqualTo(82);
        assertThat(entity.getCoverageRatio()).isEqualTo(100);
        assertThat(entity.getUpdatedAt()).isEqualTo(updatedAt);
    }
}
