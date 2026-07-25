package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository.MatchingDeckOffer;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository.MatchingDeckCandidate;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Decks de swipe (contrat squad web §5.5) : pré-triés et pré-filtrés en SQL —
 * exclut les cibles déjà swipées LEFT ou déjà matchées, priorité aux cibles
 * où l'autre côté a déjà swipé RIGHT.
 */
@Service
@Transactional(readOnly = true)
public class GetMatchingDeckUseCase {

    public record Page<T>(List<T> content, long totalElements) {}

    private final JobOfferRepository jobOffers;
    private final RecruitmentActorRepository actors;

    public GetMatchingDeckUseCase(JobOfferRepository jobOffers, RecruitmentActorRepository actors) {
        this.jobOffers = jobOffers;
        this.actors = actors;
    }

    /** GET /job-offers/matching-deck (candidat). */
    public Page<MatchingDeckOffer> candidateDeck(UUID candidateId, int page, int size) {
        return new Page<>(jobOffers.findMatchingDeckForCandidate(candidateId, page, size),
            jobOffers.countMatchingDeckForCandidate(candidateId));
    }

    /** GET /job-offers/{jobId}/candidates/matching-deck (recruteur, propriétaire de l'offre). */
    public Page<MatchingDeckCandidate> recruiterDeck(UUID recruiterId, UUID jobOfferId, int page, int size) {
        var offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        return new Page<>(actors.findMatchingDeckForJobOffer(jobOfferId, page, size),
            actors.countMatchingDeckForJobOffer(jobOfferId));
    }
}
