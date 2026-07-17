package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobOpportunityOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobOpportunityOfferRepository;
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
 * <p><b>Décision de cadrage du 16/07</b> : le sourcing est direct — « Recruit »
 * part d'un profil du deck, sans exiger ni match ni candidature APPROVED. Les
 * seuls garde-fous sont structurels : le destinataire doit être un acteur
 * candidat/étudiant actif connu de la projection Identity (fin du
 * {@code candidateId} sorti de nulle part), et l'offre référencée doit
 * appartenir au recruteur appelant. Les événements de domaine sont publiés
 * après persistance (le contrôleur les jetait).
 */
@Service
@Transactional
public class SendOpportunityOfferUseCase {

    private final JobOpportunityOfferRepository repository;
    private final JobOfferRepository jobOffers;
    private final RecruitmentActorRepository actors;
    private final ApplicationEventPublisher events;

    public SendOpportunityOfferUseCase(JobOpportunityOfferRepository repository,
                                       JobOfferRepository jobOffers,
                                       RecruitmentActorRepository actors,
                                       ApplicationEventPublisher events) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.actors = actors;
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

        JobOpportunityOffer offer = JobOpportunityOffer.send(recruiterId, candidateId, jobOfferId);
        JobOpportunityOffer saved = repository.save(offer);
        offer.domainEvents().forEach(events::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
