package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.UUID;

public interface JpaApplicationRepository extends JpaRepository<ApplicationEntity, UUID> {
    java.util.Optional<ApplicationEntity> findByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    boolean existsByCandidateIdAndJobOfferId(UUID candidateId, UUID jobOfferId);
    Page<ApplicationEntity> findByCandidateIdAndStatus(UUID candidateId, ApplicationStatus status, Pageable pageable);
    Page<ApplicationEntity> findByCandidateId(UUID candidateId, Pageable pageable);
    Page<ApplicationEntity> findByJobOfferIdAndStatus(UUID jobOfferId, ApplicationStatus status, Pageable pageable);
    Page<ApplicationEntity> findByJobOfferId(UUID jobOfferId, Pageable pageable);
    long countByCandidateIdAndStatus(UUID candidateId, ApplicationStatus status);
    long countByCandidateId(UUID candidateId);
    long countByJobOfferIdAndStatus(UUID jobOfferId, ApplicationStatus status);
    long countByJobOfferId(UUID jobOfferId);

    @Query("select application.jobOfferId, count(application) from ApplicationEntity application " +
           "where application.jobOfferId in :jobOfferIds group by application.jobOfferId")
    List<Object[]> countGroupedByJobOfferId(List<UUID> jobOfferIds);
}
