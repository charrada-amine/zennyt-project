package com.zennyt.recruitment.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.UUID;

public interface JpaRecruitmentActorRepository
        extends JpaRepository<RecruitmentActorEntity, UUID> {

    // Object[] = {RecruitmentActorEntity, SwipeDirection du swipe candidat réciproque (ou null)}.
    // Exclut les candidats swipés LEFT par ce recruteur ou déjà matchés pour cette offre ;
    // priorité à ceux ayant déjà swipé RIGHT sur cette offre (contrat squad web §5.5).
    @Query("SELECT a, candidateSwipe.direction FROM RecruitmentActorEntity a " +
           "LEFT JOIN SwipeEntity ownSwipe ON ownSwipe.jobOfferId = :jobOfferId " +
           "  AND ownSwipe.candidateId = a.publicUserId AND ownSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.RECRUITER " +
           "LEFT JOIN SwipeEntity candidateSwipe ON candidateSwipe.jobOfferId = :jobOfferId " +
           "  AND candidateSwipe.candidateId = a.publicUserId AND candidateSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.CANDIDATE " +
           "LEFT JOIN MatchEntity m ON m.jobOfferId = :jobOfferId AND m.candidateId = a.publicUserId " +
           "WHERE a.role IN ('CANDIDATE', 'STUDENT') AND a.active = true AND m IS NULL " +
           "AND (ownSwipe IS NULL OR ownSwipe.direction <> com.zennyt.recruitment.domain.vo.SwipeDirection.LEFT) " +
           "ORDER BY CASE WHEN candidateSwipe.direction = com.zennyt.recruitment.domain.vo.SwipeDirection.RIGHT THEN 0 ELSE 1 END, " +
           "a.lastEventAt DESC")
    Page<Object[]> findMatchingDeckForJobOffer(UUID jobOfferId, Pageable pageable);

    @Query("SELECT COUNT(a) FROM RecruitmentActorEntity a " +
           "LEFT JOIN SwipeEntity ownSwipe ON ownSwipe.jobOfferId = :jobOfferId " +
           "  AND ownSwipe.candidateId = a.publicUserId AND ownSwipe.side = com.zennyt.recruitment.domain.vo.SwipeSide.RECRUITER " +
           "LEFT JOIN MatchEntity m ON m.jobOfferId = :jobOfferId AND m.candidateId = a.publicUserId " +
           "WHERE a.role IN ('CANDIDATE', 'STUDENT') AND a.active = true AND m IS NULL " +
           "AND (ownSwipe IS NULL OR ownSwipe.direction <> com.zennyt.recruitment.domain.vo.SwipeDirection.LEFT)")
    long countMatchingDeckForJobOffer(UUID jobOfferId);
}
