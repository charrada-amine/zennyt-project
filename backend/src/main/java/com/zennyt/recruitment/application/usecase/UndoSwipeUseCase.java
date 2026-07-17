package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : annuler un swipe (undo).
 *
 * <p>Idempotent : un swipe déjà supprimé renvoie silencieusement (204 côté API,
 * jamais 404). Si le swipe était un LIKE, le match associé à la paire
 * (candidat, offre) est supprimé dans la même transaction ; {@code matchId}
 * explicite est aussi honoré s'il est fourni par le client.
 */
@Service
@Transactional
public class UndoSwipeUseCase {

    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;

    public UndoSwipeUseCase(SwipeRepository swipeRepository, MatchRepository matchRepository) {
        this.swipeRepository = swipeRepository;
        this.matchRepository = matchRepository;
    }

    public void execute(UUID swipeId, UUID actorId) {
        Swipe swipe = swipeRepository.findById(swipeId).orElse(null);
        if (swipe != null) {
            if (!swipe.actorId().equals(actorId)) {
                throw new ForbiddenException("Ce swipe ne vous appartient pas");
            }
            if (swipe.direction() == SwipeDirection.LIKE) {
                matchRepository.findByCandidateIdAndJobOfferId(swipe.candidateId(), swipe.jobOfferId())
                    .ifPresent(m -> matchRepository.deleteById(m.id()));
            }
            swipeRepository.deleteById(swipeId);
        }
    }
}
