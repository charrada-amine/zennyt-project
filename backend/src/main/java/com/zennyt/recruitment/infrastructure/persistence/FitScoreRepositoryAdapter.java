package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
import java.util.UUID;

@Component
public class FitScoreRepositoryAdapter implements FitScoreRepository {
    private final JpaFitScoreRepository jpa;
    public FitScoreRepositoryAdapter(JpaFitScoreRepository jpa) { this.jpa = jpa; }

    /** Upsert : un seul score par paire (candidat, offre) — le dernier callback IA gagne. */
    @Override @Transactional public FitScore save(FitScore f) {
        jpa.deleteByCandidateIdAndJobOfferId(f.candidateId(), f.jobOfferId());
        return toDomain(jpa.save(toEntity(f)));
    }
    @Override public Optional<FitScore> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(candidateId, jobOfferId).map(this::toDomain);
    }

    private FitScoreEntity toEntity(FitScore f) { return new FitScoreEntity(f.id(), f.candidateId(), f.jobOfferId(), f.score(), f.computedAt()); }
    private FitScore toDomain(FitScoreEntity e) { return FitScore.rehydrate(e.getId(), e.getCandidateId(), e.getJobOfferId(), e.getScore(), e.getComputedAt()); }
}
