package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : changer le statut d'une offre (publier, masquer, clôturer). */
@Service
@Transactional
public class ChangeJobOfferStatusUseCase {

    private final JobOfferRepository repository;
    private final ApplicationEventPublisher eventPublisher;

    public ChangeJobOfferStatusUseCase(JobOfferRepository repository, ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID jobOfferId, UUID recruiterId, JobOfferStatus newStatus) {
        JobOffer offer = repository.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Seul le recruteur propriétaire peut modifier le statut");
        }
        offer.changeStatus(newStatus);
        JobOffer saved = repository.save(offer);
        // Publier depuis `offer` et non `saved` : l'adaptateur de persistance reconstruit
        // un agrégat neuf (rehydrate), qui ne porte donc aucun événement enregistré.
        // Avec `saved`, JobOfferStatusChangedEvent n'était jamais publié — ni le
        // précalcul à la publication, ni la purge à la fermeture ne se déclenchaient.
        // Même ordre que CreateJobOfferUseCase, qui publie bien depuis l'agrégat modifié.
        offer.domainEvents().forEach(eventPublisher::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
