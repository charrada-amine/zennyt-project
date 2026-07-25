package com.zennyt.recruitment.infrastructure.persistence;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Component
public class SwipeRepositoryAdapter implements SwipeRepository {
    private final JpaSwipeRepository jpa;
    public SwipeRepositoryAdapter(JpaSwipeRepository jpa) { this.jpa = jpa; }

    @Override public Swipe save(Swipe s) { return toDomain(jpa.save(toEntity(s))); }

    @Override public Optional<Swipe> find(UUID jobOfferId, UUID candidateId, SwipeSide side) {
        return jpa.findByJobOfferIdAndCandidateIdAndSide(jobOfferId, candidateId, side).map(this::toDomain);
    }

    @Override public void delete(UUID jobOfferId, UUID candidateId, SwipeSide side) {
        jpa.deleteByJobOfferIdAndCandidateIdAndSide(jobOfferId, candidateId, side);
    }

    @Override public Map<UUID, Long> countRightByJobOfferIds(List<UUID> jobOfferIds) {
        if (jobOfferIds.isEmpty()) return Map.of();
        Map<UUID, Long> counts = new HashMap<>();
        for (Object[] row : jpa.countRightByJobOfferIds(jobOfferIds)) {
            counts.put((UUID) row[0], (Long) row[1]);
        }
        return counts;
    }

    private SwipeEntity toEntity(Swipe s) {
        return new SwipeEntity(s.id(), s.jobOfferId(), s.candidateId(), s.side(), s.direction(), s.createdAt());
    }
    private Swipe toDomain(SwipeEntity e) {
        return Swipe.rehydrate(e.getId(), e.getJobOfferId(), e.getCandidateId(), e.getSide(), e.getDirection(), e.getCreatedAt());
    }
}
