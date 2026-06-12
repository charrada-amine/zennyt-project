package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Application;

import java.util.Optional;
import java.util.UUID;

/**
 * Port (interface) du repository de candidatures.
 *
 * <p>Défini dans le domaine, implémenté dans l'infrastructure. Le domaine
 * dépend de cette abstraction, jamais de JPA. C'est l'inversion de dépendance
 * au cœur de l'architecture hexagonale.
 */
public interface ApplicationRepository {

    Application save(Application application);

    Optional<Application> findById(UUID id);

    boolean existsByCandidateIdAndJobId(UUID candidateId, UUID jobId);
}
