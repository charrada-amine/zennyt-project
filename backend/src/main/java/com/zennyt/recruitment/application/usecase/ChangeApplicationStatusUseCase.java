package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : changer le statut d'une candidature (recruteur). */
@Service
@Transactional
public class ChangeApplicationStatusUseCase {

    private final ApplicationRepository repository;
    private final JobOfferRepository jobOffers;
    private final ApplicationEventPublisher eventPublisher;

    public ChangeApplicationStatusUseCase(ApplicationRepository repository,
                                          JobOfferRepository jobOffers,
                                          ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.eventPublisher = eventPublisher;
    }

    public Application execute(UUID applicationId, UUID recruiterId, ApplicationStatus newStatus) {
        Application app = repository.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        var offer = jobOffers.findById(app.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette candidature appartient à une autre offre");
        }
        ApplicationStatus previousStatus = app.status();
        app.changeStatus(newStatus);
        Application saved = repository.save(app);

        eventPublisher.publishEvent(ApplicationStatusChangedEvent.of(
            saved.id(), saved.candidateId(), saved.jobOfferId(),
            offer.recruiterId(), offer.title(), previousStatus, saved.status()));

        return saved;
    }
}
