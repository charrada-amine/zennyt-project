package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

@Component
public class FitScoreDismissalRepositoryAdapter implements FitScoreDismissalRepository {
    private final JpaFitScoreDismissalRepository jpa;

    public FitScoreDismissalRepositoryAdapter(JpaFitScoreDismissalRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public void dismiss(UUID recruiterId, UUID candidateId, UUID jobOfferId, Instant dismissedAt) {
        jpa.save(new FitScoreDismissalEntity(recruiterId, candidateId, jobOfferId, dismissedAt));
    }

    @Override
    public boolean isDismissed(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        return jpa.existsByRecruiterIdAndCandidateIdAndJobOfferId(
            recruiterId, candidateId, jobOfferId);
    }
}
