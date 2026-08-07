package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.SwipeSide;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaSwipeRepository extends JpaRepository<SwipeEntity, UUID> {
    Optional<SwipeEntity> findByJobOfferIdAndCandidateIdAndSide(UUID jobOfferId, UUID candidateId, SwipeSide side);
    void deleteByJobOfferIdAndCandidateIdAndSide(UUID jobOfferId, UUID candidateId, SwipeSide side);

    @Query("SELECT s.jobOfferId, COUNT(s) FROM SwipeEntity s " +
           "WHERE s.jobOfferId IN :jobOfferIds AND s.side = com.zennyt.recruitment.domain.vo.SwipeSide.CANDIDATE " +
           "AND s.direction = com.zennyt.recruitment.domain.vo.SwipeDirection.RIGHT " +
           "GROUP BY s.jobOfferId")
    List<Object[]> countRightByJobOfferIds(List<UUID> jobOfferIds);
}
