package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.command.SubmitApplicationCommand;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Cas d'usage : soumettre une candidature.
 *
 * <p>Vérifie l'unicité (un candidat ne postule qu'une fois par offre),
 * crée l'agrégat, le persiste, puis publie les événements de domaine.
 */
@Service
@Transactional
public class SubmitApplicationUseCase {

    private final ApplicationRepository repository;
    private final JobOfferRepository jobOffers;
    private final ApplicationEventPublisher eventPublisher;

    public SubmitApplicationUseCase(ApplicationRepository repository,
                                    JobOfferRepository jobOffers,
                                    ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.eventPublisher = eventPublisher;
    }

    public Application execute(SubmitApplicationCommand cmd) {
        if (repository.existsByCandidateIdAndJobOfferId(cmd.candidateId(), cmd.jobOfferId())) {
            throw new ConflictException("Vous avez déjà postulé à cette offre");
        }
        var offer = jobOffers.findById(cmd.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (offer.status() != JobOfferStatus.ACTIVE) {
            throw new ConflictException("Cette offre n'accepte plus de candidatures");
        }

        Application application = Application.submit(cmd.candidateId(), cmd.jobOfferId());
        Application saved = repository.save(application);

        saved.domainEvents().forEach(eventPublisher::publishEvent);
        saved.clearEvents();

        return saved;
    }
}
