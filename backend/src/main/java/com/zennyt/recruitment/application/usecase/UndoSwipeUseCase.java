package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : annuler un swipe (undo).
 *
 * <p>404 s'il n'y a pas de swipe actif à annuler pour ce côté (contrat squad
 * web §5.4). Si un Match existait pour la paire, il est supprimé dans la même
 * transaction ; le swipe de l'autre côté n'est jamais touché — il redevient
 * simplement visible dans le deck de son auteur.
 */
@Service
@Transactional
public class UndoSwipeUseCase {

    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;
    private final JobOfferRepository jobOfferRepository;

    public UndoSwipeUseCase(SwipeRepository swipeRepository, MatchRepository matchRepository,
                            JobOfferRepository jobOfferRepository) {
        this.swipeRepository = swipeRepository;
        this.matchRepository = matchRepository;
        this.jobOfferRepository = jobOfferRepository;
    }

    public void execute(UUID actorId, UUID jobOfferId, UUID candidateId, SwipeSide side) {
        if (side == SwipeSide.RECRUITER) {
            JobOffer offer = jobOfferRepository.findById(jobOfferId)
                .orElseThrow(() -> new NotFoundException("Offre introuvable"));
            if (!offer.recruiterId().equals(actorId)) {
                throw new ForbiddenException("Cette offre ne vous appartient pas");
            }
        }
        Swipe swipe = swipeRepository.find(jobOfferId, candidateId, side)
            .orElseThrow(() -> new NotFoundException("Aucun swipe actif à annuler"));

        matchRepository.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .ifPresent(m -> matchRepository.deleteById(m.id()));
        swipeRepository.delete(jobOfferId, candidateId, swipe.side());
    }
}
