package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
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

    @Query("SELECT j.id FROM JobOfferEntity j WHERE j.assessmentId = :assessmentId")
    java.util.List<UUID> findIdsByAssessmentId(UUID assessmentId);

    @Query("SELECT j.assessmentId, COUNT(j) FROM JobOfferEntity j " +
           "WHERE j.assessmentId IN :assessmentIds GROUP BY j.assessmentId")
    java.util.List<Object[]> countGroupedByAssessmentId(java.util.List<UUID> assessmentIds);

    // CAST(:p AS string) sur chaque référence dans LOWER : sans cela PostgreSQL
    // infère les paramètres null comme `bytea` et la fonction LOWER échoue.
    // Les filtres enum sont typés : comparer un paramètre String à un champ
    // @Enumerated lève QueryArgumentException sous Hibernate 6 (500 en recherche filtrée).
    @Query("SELECT j FROM JobOfferEntity j WHERE j.status = 'ACTIVE' " +
           "AND (CAST(:query AS string) IS NULL OR LOWER(j.title) LIKE LOWER(CONCAT('%', CAST(:query AS string), '%'))) " +
           "AND (CAST(:location AS string) IS NULL OR LOWER(j.locationCity) LIKE LOWER(CONCAT('%', CAST(:location AS string), '%'))) " +
           "AND (:contractType IS NULL OR j.contractType = :contractType) " +
           "AND (:experienceLevel IS NULL OR j.experienceLevel = :experienceLevel)")
    Page<JobOfferEntity> search(String query, String location, ContractType contractType,
                                ExperienceLevel experienceLevel, Pageable pageable);

    @Query("SELECT j FROM JobOfferEntity j LEFT JOIN FitScoreEntity f " +
           "ON f.jobOfferId = j.id AND f.candidateId = :candidateId " +
           "WHERE j.status = 'ACTIVE' " +
           "ORDER BY CASE WHEN f.score IS NULL THEN 1 ELSE 0 END, f.score DESC, j.postedAt DESC")
    Page<JobOfferEntity> findFeedForCandidate(UUID candidateId, Pageable pageable);

    // Object[] = {JobOfferEntity, SwipeDirection du swipe recruteur réciproque (ou null)}.
    // Exclut les offres swipées LEFT par ce candidat ou déjà matchées ; priorité aux
    // offres où le recruteur a déjà swipé RIGHT sur ce candidat (contrat squad web §5.5).
    @Query("SELECT j, recruiterSwipe.direction FROM JobOfferEntity j " +
           "LEFT JOIN SwipeEntity ownSwipe ON ownSwipe.jobOfferId = j.id " +
           "  AND ownSwipe.candidateId = :candidateId AND ownSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.CANDIDATE " +
           "LEFT JOIN SwipeEntity recruiterSwipe ON recruiterSwipe.jobOfferId = j.id " +
           "  AND recruiterSwipe.candidateId = :candidateId AND recruiterSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.RECRUITER " +
           "LEFT JOIN MatchEntity m ON m.jobOfferId = j.id AND m.candidateId = :candidateId " +
           "WHERE j.status = 'ACTIVE' AND m IS NULL " +
           "AND (ownSwipe IS NULL OR ownSwipe.direction <> com.zennyt.recruitment.domain.vo.SwipeDirection.LEFT) " +
           "ORDER BY CASE WHEN recruiterSwipe.direction = com.zennyt.recruitment.domain.vo.SwipeDirection.RIGHT THEN 0 ELSE 1 END, " +
           "j.postedAt DESC")
    Page<Object[]> findMatchingDeckForCandidate(UUID candidateId, Pageable pageable);

    @Query("SELECT COUNT(j) FROM JobOfferEntity j " +
           "LEFT JOIN SwipeEntity ownSwipe ON ownSwipe.jobOfferId = j.id " +
           "  AND ownSwipe.candidateId = :candidateId AND ownSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.CANDIDATE " +
           "LEFT JOIN MatchEntity m ON m.jobOfferId = j.id AND m.candidateId = :candidateId " +
           "WHERE j.status = 'ACTIVE' AND m IS NULL " +
           "AND (ownSwipe IS NULL OR ownSwipe.direction <> com.zennyt.recruitment.domain.vo.SwipeDirection.LEFT)")
    long countMatchingDeckForCandidate(UUID candidateId);
}
