package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface JpaApplicationRepository extends JpaRepository<ApplicationEntity, UUID> {
    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    Page<ApplicationEntity> findByCandidateIdAndStatus(UUID candidateId, ApplicationStatus status, Pageable pageable);
    Page<ApplicationEntity> findByCandidateId(UUID candidateId, Pageable pageable);
    Page<ApplicationEntity> findByJobOfferIdAndStatus(UUID jobOfferId, ApplicationStatus status, Pageable pageable);
    Page<ApplicationEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByCandidateIdAndStatus(UUID candidateId, ApplicationStatus status);
    long countByCandidateId(UUID candidateId);
    long countByJobOfferIdAndStatus(UUID jobOfferId, ApplicationStatus status);
    long countByJobOfferId(UUID jobOfferId);
}
