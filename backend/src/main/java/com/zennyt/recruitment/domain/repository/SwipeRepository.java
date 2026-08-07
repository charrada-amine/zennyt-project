package com.zennyt.recruitment.domain.repository;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.vo.SwipeSide;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Port du repository de swipes. */
public interface SwipeRepository {

    Swipe save(Swipe swipe);

    /** Swipe actif pour ce côté de la paire (offre, candidat), s'il existe. */
    Optional<Swipe> find(UUID jobOfferId, UUID candidateId, SwipeSide side);

    void delete(UUID jobOfferId, UUID candidateId, SwipeSide side);

    /** Nombre de swipes RIGHT côté candidat par offre (vue liste recruteur — applicantCount). */
    Map<UUID, Long> countRightByJobOfferIds(List<UUID> jobOfferIds);
}
