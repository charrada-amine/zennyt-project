package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class SwipeRepositoryAdapter implements SwipeRepository {
    private final JpaSwipeRepository jpa;
    public SwipeRepositoryAdapter(JpaSwipeRepository jpa) { this.jpa = jpa; }

    @Override public Swipe save(Swipe s) { return toDomain(jpa.save(toEntity(s))); }

    @Override public Optional<Swipe> findById(UUID id) { return jpa.findById(id).map(this::toDomain); }

    @Override public Optional<Swipe> findByActorAndPair(UUID actorId, UUID candidateId, UUID jobOfferId) {
        return jpa.findFirstByActorIdAndCandidateIdAndJobOfferId(actorId, candidateId, jobOfferId).map(this::toDomain);
    }

    @Override public void deleteById(UUID id) { jpa.deleteById(id); }

    @Override public List<UUID> findTargetIdsByActorId(UUID actorId, UUID jobOfferId) {
        var swipes = jobOfferId != null ? jpa.findByActorIdAndJobOfferId(actorId, jobOfferId) : jpa.findByActorId(actorId);
        return swipes.stream().map(SwipeEntity::getTargetId).toList();
    }

    @Override public boolean existsByActorIdAndCandidateIdAndJobOfferId(UUID actorId, UUID candidateId, UUID jobOfferId) {
        return jpa.existsByActorIdAndCandidateIdAndJobOfferId(actorId, candidateId, jobOfferId);
    }

    @Override public Optional<Swipe> findMutualLike(UUID candidateId, UUID jobOfferId,
                                                    String mutualTargetType, SwipeDirection direction) {
        return jpa.findByCandidateIdAndJobOfferIdAndTargetTypeAndDirection(
            candidateId, jobOfferId, mutualTargetType, direction).map(this::toDomain);
    }

    private SwipeEntity toEntity(Swipe s) { return new SwipeEntity(s.id(), s.actorId(), s.targetId(), s.targetType(), s.candidateId(), s.jobOfferId(), s.direction(), s.swipedAt()); }
    private Swipe toDomain(SwipeEntity e) { return Swipe.rehydrate(e.getId(), e.getActorId(), e.getTargetId(), e.getTargetType(), e.getCandidateId(), e.getJobOfferId(), e.getDirection(), e.getSwipedAt()); }
}
