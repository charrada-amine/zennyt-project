package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Envoie une offre d'opportunité (proposition salariale) à un candidat.
 *
 * <p><b>Décision de cadrage du 16/07, révisée le 20/07, révisée à nouveau
 * (contrat squad web, suppression de l'entité Application)</b> : « Recruit »
 * (bouton « Good Fit ») exige désormais un {@code Match} {@code ACTIVE} sur
 * cette offre (parcours swipe mutuel) — le tunnel de présélection/candidature
 * n'existe plus. Les garde-fous structurels restent : le destinataire doit
 * être un acteur candidat/étudiant actif connu de la projection Identity, et
 * l'offre référencée doit appartenir au recruteur appelant. Les événements de
 * domaine sont publiés après persistance.
 */
@Service
@Transactional
public class SendOpportunityOfferUseCase {

    private final JobOpportunityOfferRepository repository;
    private final JobOfferRepository jobOffers;
    private final RecruitmentActorRepository actors;
    private final MatchRepository matches;
    private final ApplicationEventPublisher events;

    public SendOpportunityOfferUseCase(JobOpportunityOfferRepository repository,
                                       JobOfferRepository jobOffers,
                                       RecruitmentActorRepository actors,
                                       MatchRepository matches,
                                       ApplicationEventPublisher events) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.actors = actors;
        this.matches = matches;
        this.events = events;
    }

    public JobOpportunityOffer execute(UUID recruiterId, UUID candidateId, UUID jobOfferId) {
        var actor = actors.findById(candidateId)
            .filter(a -> a.active())
            .orElseThrow(() -> new NotFoundException("Candidat introuvable : " + candidateId));
        if ("RECRUITER".equalsIgnoreCase(actor.role())) {
            throw new IllegalArgumentException("La cible d'une opportunité doit être un candidat");
        }

        JobOffer jobOffer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable : " + jobOfferId));
        if (!jobOffer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }

        boolean matched = matches.findByCandidateIdAndJobOfferId(candidateId, jobOfferId).isPresent();
        if (!matched) {
            throw new ForbiddenException(
                "Le candidat doit être matché sur cette offre pour recevoir une opportunité");
        }

        JobOpportunityOffer offer = JobOpportunityOffer.send(recruiterId, candidateId, jobOfferId);
        JobOpportunityOffer saved = repository.save(offer);
        offer.domainEvents().forEach(events::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
