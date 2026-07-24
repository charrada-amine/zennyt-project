package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : enregistrer un swipe (candidat ou recruteur) sur une paire
 * (offre, candidat).
 *
 * <p>Transaction unique (contrat squad web §5.5) : insertion du swipe,
 * vérification du swipe réciproque, création du Match si les deux côtés ont
 * swipé RIGHT — élimine les races entre swipes quasi simultanés des deux côtés.
 * Aucune réécriture silencieuse : un swipe déjà actif pour ce côté est un 409
 * (il faut d'abord l'annuler).
 */
@Service
@Transactional
public class RecordSwipeUseCase {

    public record Result(Swipe swipe, Match match) {}

    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;
    private final JobOfferRepository jobOfferRepository;
    private final RecruitmentActorRepository actors;
    private final ApplicationEventPublisher eventPublisher;

    public RecordSwipeUseCase(SwipeRepository swipeRepository, MatchRepository matchRepository,
                              JobOfferRepository jobOfferRepository, RecruitmentActorRepository actors,
                              ApplicationEventPublisher eventPublisher) {
        this.swipeRepository = swipeRepository;
        this.matchRepository = matchRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.actors = actors;
        this.eventPublisher = eventPublisher;
    }

    /**
     * @param actorId candidat (side=CANDIDATE, alors {@code actorId == candidateId}) ou
     *                recruteur propriétaire de l'offre (side=RECRUITER)
     * @param candidateId le candidat concerné par ce swipe
     */
    public Result execute(UUID actorId, UUID jobOfferId, UUID candidateId, SwipeSide side, SwipeDirection direction) {
        JobOffer offer = jobOfferRepository.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));

        if (side == SwipeSide.RECRUITER) {
            if (!offer.recruiterId().equals(actorId)) {
                throw new ForbiddenException("Cette offre ne vous appartient pas");
            }
            actors.findById(candidateId).filter(a -> a.active())
                .orElseThrow(() -> new NotFoundException("Candidat introuvable : " + candidateId));
        }

        if (offer.status() != JobOfferStatus.ACTIVE) {
            throw new ConflictException("JOB_NOT_ACTIVE", "Cette offre n'est pas active");
        }
        if (matchRepository.findByCandidateIdAndJobOfferId(candidateId, jobOfferId).isPresent()) {
            throw new ConflictException("ALREADY_MATCHED", "Un match existe déjà pour cette paire");
        }
        if (swipeRepository.find(jobOfferId, candidateId, side).isPresent()) {
            throw new ConflictException("SWIPE_ALREADY_EXISTS",
                "Un swipe existe déjà pour cette paire — annulez-le avant de re-swiper");
        }

        Swipe swipe = Swipe.record(jobOfferId, candidateId, side, direction);
        Swipe saved = swipeRepository.save(swipe);
        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearEvents();

        Match match = null;
        if (direction == SwipeDirection.RIGHT) {
            var reciprocal = swipeRepository.find(jobOfferId, candidateId, saved.mutualSide());
            if (reciprocal.isPresent() && reciprocal.get().direction() == SwipeDirection.RIGHT) {
                match = Match.create(candidateId, jobOfferId, offer.recruiterId());
                match = matchRepository.save(match);
                match.domainEvents().forEach(eventPublisher::publishEvent);
                match.clearEvents();
            }
        }
        return new Result(saved, match);
    }
}
