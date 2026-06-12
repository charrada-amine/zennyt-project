package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/** Repository Spring Data JPA technique (interne à l'infrastructure). */
public interface JpaApplicationRepository extends JpaRepository<ApplicationEntity, UUID> {
    boolean existsByCandidateIdAndJobId(UUID candidateId, UUID jobId);
}
