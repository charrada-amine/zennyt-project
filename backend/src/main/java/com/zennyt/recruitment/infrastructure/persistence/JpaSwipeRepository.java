package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.vo.SwipeDirection;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface JpaSwipeRepository extends JpaRepository<SwipeEntity, UUID> {
    boolean existsByActorIdAndCandidateIdAndJobOfferId(UUID actorId, UUID candidateId, UUID jobOfferId);
    Optional<SwipeEntity> findFirstByActorIdAndCandidateIdAndJobOfferId(UUID actorId, UUID candidateId, UUID jobOfferId);
    List<SwipeEntity> findByActorId(UUID actorId);
    List<SwipeEntity> findByActorIdAndJobOfferId(UUID actorId, UUID jobOfferId);
    Optional<SwipeEntity> findByCandidateIdAndJobOfferIdAndTargetTypeAndDirection(
        UUID candidateId, UUID jobOfferId, String targetType, SwipeDirection direction);
}
