package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : enregistrer un swipe (candidat ou recruteur).
 *
 * <p>Si le swipe est un LIKE et que le côté opposé a déjà swipé LIKE,
 * un Match mutuel est automatiquement créé et son événement publié.
 */
@Service
@Transactional
public class RecordSwipeUseCase {

    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;
    private final JobOfferRepository jobOfferRepository;
    private final ApplicationEventPublisher eventPublisher;

    public RecordSwipeUseCase(SwipeRepository swipeRepository, MatchRepository matchRepository,
                               JobOfferRepository jobOfferRepository, ApplicationEventPublisher eventPublisher) {
        this.swipeRepository = swipeRepository;
        this.matchRepository = matchRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.eventPublisher = eventPublisher;
    }

    public record SwipeResult(Swipe swipe, Match match) {}

    /**
     * Enregistre un swipe et crée un match si — et seulement si — le côté opposé a
     * déjà swipé LIKE sur la même paire {@code (candidateId, jobOfferId)}.
     *
     * @param jobOfferId l'offre concernée ; ignoré pour un swipe candidat (déduit de
     *                   {@code targetId}), <b>requis</b> pour un swipe recruteur sur candidat.
     */
    public SwipeResult execute(UUID actorId, UUID targetId, String targetType,
                               UUID jobOfferId, SwipeDirection direction) {
        if (!Swipe.TARGET_JOB_OFFER.equals(targetType)
                && !Swipe.TARGET_CANDIDATE.equals(targetType)) {
            throw new IllegalArgumentException("Type de cible invalide");
        }
        if (Swipe.TARGET_CANDIDATE.equals(targetType) && jobOfferId == null) {
            throw new IllegalArgumentException("L'offre est obligatoire pour un swipe recruteur");
        }
        UUID resolvedOfferId = Swipe.TARGET_JOB_OFFER.equals(targetType) ? targetId : jobOfferId;
        JobOffer offer = jobOfferRepository.findById(resolvedOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (Swipe.TARGET_CANDIDATE.equals(targetType)
                && !offer.recruiterId().equals(actorId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        if (Swipe.TARGET_JOB_OFFER.equals(targetType)
                && offer.status() != JobOfferStatus.ACTIVE) {
            throw new IllegalArgumentException("Cette offre n'est pas active");
        }
        // On normalise d'abord la paire (candidateId, jobOfferId)…
        Swipe swipe = Swipe.record(actorId, targetId, targetType, jobOfferId, direction);

        // …puis upsert sur (acteur, candidat, offre) : re-swiper la même cible met à
        // jour le swipe existant (idempotence) au lieu de le dupliquer. Un recruteur
        // peut toujours swiper le même candidat pour des offres différentes.
        var existing = swipeRepository.findByActorAndPair(actorId, swipe.candidateId(), swipe.jobOfferId());
        if (existing.isPresent()) {
            Swipe previous = existing.get();
            if (previous.direction() == direction) {
                Match existingMatch = direction == SwipeDirection.LIKE
                    ? matchRepository.findByCandidateIdAndJobOfferId(
                        previous.candidateId(), previous.jobOfferId()).orElse(null)
                    : null;
                return new SwipeResult(previous, existingMatch);
            }
            // Direction changée : remplacer le swipe et nettoyer un match devenu orphelin.
            swipeRepository.deleteById(previous.id());
            if (previous.direction() == SwipeDirection.LIKE) {
                matchRepository.findByCandidateIdAndJobOfferId(previous.candidateId(), previous.jobOfferId())
                    .ifPresent(m -> matchRepository.deleteById(m.id()));
            }
        }

        Swipe saved = swipeRepository.save(swipe);
        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearEvents();

        Match match = null;
        if (direction == SwipeDirection.LIKE) {
            // On cherche le swipe OPPOSÉ (type de cible inverse) sur la même paire :
            // cela exclut structurellement le swipe que l'on vient d'enregistrer.
            var mutual = swipeRepository.findMutualLike(
                saved.candidateId(), saved.jobOfferId(), saved.mutualTargetType(), SwipeDirection.LIKE);
            if (mutual.isPresent()) {
                JobOffer matchedOffer = jobOfferRepository.findById(saved.jobOfferId()).orElseThrow();
                match = Match.create(saved.candidateId(), saved.jobOfferId(),
                    matchedOffer.recruiterId(), matchedOffer.title());
                match = matchRepository.save(match);
                match.domainEvents().forEach(eventPublisher::publishEvent);
                match.clearEvents();
            }
        }

        return new SwipeResult(saved, match);
    }
}
