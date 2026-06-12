package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Adaptateur de persistance : implémente le port {@link ApplicationRepository}
 * du domaine en s'appuyant sur Spring Data JPA.
 *
 * <p>Rôle clé : convertir (mapper) entre l'agrégat {@code Application} (domaine
 * pur) et {@code ApplicationEntity} (JPA). Le domaine ne connaît jamais JPA.
 */
@Component
public class ApplicationRepositoryAdapter implements ApplicationRepository {

    private final JpaApplicationRepository jpa;

    public ApplicationRepositoryAdapter(JpaApplicationRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Application save(Application application) {
        ApplicationEntity entity = toEntity(application);
        return toDomain(jpa.save(entity));
    }

    @Override
    public Optional<Application> findById(UUID id) {
        return jpa.findById(id).map(this::toDomain);
    }

    @Override
    public boolean existsByCandidateIdAndJobId(UUID candidateId, UUID jobId) {
        return jpa.existsByCandidateIdAndJobId(candidateId, jobId);
    }

    // ───────────── Mappers ─────────────
    private ApplicationEntity toEntity(Application a) {
        return new ApplicationEntity(
            a.id(), a.candidateId(), a.jobId(), a.coverLetter(),
            a.status(), a.appliedAt(), a.updatedAt());
    }

    private Application toDomain(ApplicationEntity e) {
        return Application.rehydrate(
            e.getId(), e.getCandidateId(), e.getJobId(), e.getCoverLetter(),
            e.getStatus(), e.getAppliedAt(), e.getUpdatedAt());
    }
}
