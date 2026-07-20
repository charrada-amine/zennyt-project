package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : changer le statut d'une candidature (recruteur).
 *
 * <p>Le recruteur ne pilote que la présélection : {@code PENDING -> SHORTLISTED}
 * ou {@code PENDING -> REJECTED}. Une fois présélectionnée, seul le candidat
 * peut répondre ({@code SHORTLISTED -> APPROVED/REJECTED}), via
 * {@link RespondToShortlistUseCase} — voir décision du 20/07.
 */
@Service
@Transactional
public class ChangeApplicationStatusUseCase {

    private final ApplicationRepository repository;
    private final JobOfferRepository jobOffers;
    private final ApplicationEventPublisher events;

    public ChangeApplicationStatusUseCase(ApplicationRepository repository,
                                          JobOfferRepository jobOffers,
                                          ApplicationEventPublisher events) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.events = events;
    }

    public Application execute(UUID applicationId, UUID recruiterId, ApplicationStatus newStatus) {
        Application app = repository.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        var offer = jobOffers.findById(app.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette candidature appartient à une autre offre");
        }
        if (newStatus == ApplicationStatus.APPROVED
                || (newStatus == ApplicationStatus.REJECTED && app.status() == ApplicationStatus.SHORTLISTED)) {
            throw new ForbiddenException("Seul le candidat peut répondre à une présélection");
        }
        app.changeStatus(newStatus);
        Application saved = repository.save(app);
        app.domainEvents().forEach(events::publishEvent);
        app.clearEvents();
        return saved;
    }
}
