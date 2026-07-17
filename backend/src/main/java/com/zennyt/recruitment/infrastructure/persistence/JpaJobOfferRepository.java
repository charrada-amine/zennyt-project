package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.UUID;

public interface JpaJobOfferRepository extends JpaRepository<JobOfferEntity, UUID> {
    Page<JobOfferEntity> findByRecruiterIdAndStatus(UUID recruiterId, JobOfferStatus status, Pageable pageable);
    Page<JobOfferEntity> findByRecruiterId(UUID recruiterId, Pageable pageable);
    long countByRecruiterIdAndStatus(UUID recruiterId, JobOfferStatus status);
    long countByRecruiterId(UUID recruiterId);
    Page<JobOfferEntity> findByStatus(JobOfferStatus status, Pageable pageable);
    long countByStatus(JobOfferStatus status);
    boolean existsByAssessmentId(UUID assessmentId);

    // CAST(:p AS string) sur chaque référence dans LOWER : sans cela PostgreSQL
    // infère les paramètres null comme `bytea` et la fonction LOWER échoue.
    @Query("SELECT j FROM JobOfferEntity j WHERE j.status = 'ACTIVE' " +
           "AND (CAST(:query AS string) IS NULL OR LOWER(j.title) LIKE LOWER(CONCAT('%', CAST(:query AS string), '%'))) " +
           "AND (CAST(:location AS string) IS NULL OR LOWER(j.locationCity) LIKE LOWER(CONCAT('%', CAST(:location AS string), '%'))) " +
           "AND (CAST(:contractType AS string) IS NULL OR j.contractType = :contractType) " +
           "AND (CAST(:experienceLevel AS string) IS NULL OR j.experienceLevel = :experienceLevel)")
    Page<JobOfferEntity> search(String query, String location, String contractType,
                                String experienceLevel, Pageable pageable);

    @Query("SELECT j FROM JobOfferEntity j LEFT JOIN FitScoreEntity f " +
           "ON f.jobOfferId = j.id AND f.candidateId = :candidateId " +
           "WHERE j.status = 'ACTIVE' " +
           "ORDER BY CASE WHEN f.score IS NULL THEN 1 ELSE 0 END, f.score DESC, j.postedAt DESC")
    Page<JobOfferEntity> findFeedForCandidate(UUID candidateId, Pageable pageable);
}
