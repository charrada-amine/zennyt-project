package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.FitScore;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class FitScoreRepositoryAdapterTest {
    @Test
    void saveUsesAtomicDatabaseUpsert() {
        JpaFitScoreRepository jpa = mock(JpaFitScoreRepository.class);
        UUID id = UUID.randomUUID();
        UUID candidateId = UUID.randomUUID();
        UUID offerId = UUID.randomUUID();
        Instant computedAt = Instant.now();
        FitScore score = FitScore.calculated(
            id, candidateId, offerId, 84, 77, 91, null, 100, computedAt);
        when(jpa.findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(candidateId, offerId))
            .thenReturn(Optional.of(new FitScoreEntity(
                id, candidateId, offerId, 84, 77, 91, null, 100, computedAt)));

        FitScore saved = new FitScoreRepositoryAdapter(jpa).save(score);

        verify(jpa).upsert(id, candidateId, offerId, 84, 77, 91, null, 100, computedAt);
        assertThat(saved.score()).isEqualTo(84);
    }
}
