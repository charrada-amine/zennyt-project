package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Port du repository de candidatures.
 *
 * <p>Défini dans le domaine, implémenté dans l'infrastructure.
 */
public interface ApplicationRepository {

    Application save(Application application);

    Optional<Application> findById(UUID id);

    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);

    List<Application> findByCandidateId(UUID candidateId, ApplicationStatus status, int page, int size);

    List<Application> findByJobOfferId(UUID jobOfferId, ApplicationStatus status, int page, int size);

    long countByCandidateId(UUID candidateId, ApplicationStatus status);

    long countByJobOfferId(UUID jobOfferId, ApplicationStatus status);
}
