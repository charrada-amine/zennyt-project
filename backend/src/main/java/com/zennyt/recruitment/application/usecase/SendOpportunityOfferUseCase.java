package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.recruitment.domain.vo.MatchStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Envoie une offre d'opportunité (proposition salariale) à un candidat.
 *
 * <p><b>Décision de cadrage du 16/07, révisée le 20/07</b> : le sourcing direct
 * sans aucune contrainte a été abandonné. « Recruit » (bouton « Good Fit »)
 * exige désormais que le candidat ait, pour cette offre, soit une candidature
 * {@code APPROVED} (parcours présélection → réponse du candidat), soit un
 * {@code Match} {@code ACTIVE} (parcours swipe mutuel) — les deux tunnels
 * convergent vers la même étape suivante. Les garde-fous structurels restent :
 * le destinataire doit être un acteur candidat/étudiant actif connu de la
 * projection Identity, et l'offre référencée doit appartenir au recruteur
 * appelant. Les événements de domaine sont publiés après persistance.
 */
@Service
@Transactional
public class SendOpportunityOfferUseCase {

    private final JobOpportunityOfferRepository repository;
    private final JobOfferRepository jobOffers;
    private final RecruitmentActorRepository actors;
    private final ApplicationRepository applications;
    private final MatchRepository matches;
    private final ApplicationEventPublisher events;

    public SendOpportunityOfferUseCase(JobOpportunityOfferRepository repository,
                                       JobOfferRepository jobOffers,
                                       RecruitmentActorRepository actors,
                                       ApplicationRepository applications,
                                       MatchRepository matches,
                                       ApplicationEventPublisher events) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.actors = actors;
        this.applications = applications;
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

        boolean approved = applications.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(a -> a.status() == ApplicationStatus.APPROVED)
            .orElse(false);
        boolean matched = matches.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(m -> m.status() == MatchStatus.ACTIVE)
            .orElse(false);
        if (!approved && !matched) {
            throw new ForbiddenException(
                "Le candidat doit être approuvé (présélection) ou matché sur cette offre pour recevoir une opportunité");
        }

        JobOpportunityOffer offer = JobOpportunityOffer.send(recruiterId, candidateId, jobOfferId);
        JobOpportunityOffer saved = repository.save(offer);
        offer.domainEvents().forEach(events::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
