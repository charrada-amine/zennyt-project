package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
import java.util.List;
import java.util.UUID;

@Component
public class FitScoreRepositoryAdapter implements FitScoreRepository {
    private final JpaFitScoreRepository jpa;
    public FitScoreRepositoryAdapter(JpaFitScoreRepository jpa) { this.jpa = jpa; }

    /** Upsert atomique : un seul score par paire — le dernier calcul gagne. */
    @Override @Transactional public FitScore save(FitScore f) {
        jpa.upsert(f.id(), f.candidateId(), f.jobOfferId(), f.score(),
            f.softSkillScore(), f.cvMatchScore(), f.computedAt());
        return jpa.findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(
                f.candidateId(), f.jobOfferId())
            .map(this::toDomain)
            .orElseThrow(() -> new IllegalStateException("Fit score introuvable après upsert"));
    }
    @Override public Optional<FitScore> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId) {
        return jpa.findFirstByCandidateIdAndJobOfferIdOrderByComputedAtDesc(candidateId, jobOfferId).map(this::toDomain);
    }
    @Override public List<FitScore> findByJobOfferIdOrderByScoreDesc(UUID jobOfferId) {
        return jpa.findByJobOfferIdOrderByScoreDesc(jobOfferId).stream().map(this::toDomain).toList();
    }
    @Override public List<FitScore> findByCandidateIdAndJobOfferIds(UUID candidateId, List<UUID> jobOfferIds) {
        if (jobOfferIds.isEmpty()) return List.of();
        return jpa.findByCandidateIdAndJobOfferIdIn(candidateId, jobOfferIds).stream()
            .map(this::toDomain).toList();
    }

    private FitScore toDomain(FitScoreEntity e) { return FitScore.rehydrate(e.getId(), e.getCandidateId(), e.getJobOfferId(), e.getScore(), e.getSoftSkillScore(), e.getCvMatchScore(), e.getComputedAt()); }
}
