package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : changer le statut d'une candidature (recruteur). */
@Service
@Transactional
public class ChangeApplicationStatusUseCase {

    private final ApplicationRepository repository;
    private final JobOfferRepository jobOffers;

    public ChangeApplicationStatusUseCase(ApplicationRepository repository,
                                          JobOfferRepository jobOffers) {
        this.repository = repository;
        this.jobOffers = jobOffers;
    }

    public Application execute(UUID applicationId, UUID recruiterId, ApplicationStatus newStatus) {
        Application app = repository.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        var offer = jobOffers.findById(app.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette candidature appartient à une autre offre");
        }
        app.changeStatus(newStatus);
        return repository.save(app);
    }
}
