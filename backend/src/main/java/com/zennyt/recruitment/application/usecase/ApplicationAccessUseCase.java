package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Lectures de candidatures avec contrôle de propriété côté serveur. */
@Service
@Transactional(readOnly = true)
public class ApplicationAccessUseCase {

    private final ApplicationRepository applications;
    private final JobOfferRepository jobOffers;

    public ApplicationAccessUseCase(ApplicationRepository applications,
                                    JobOfferRepository jobOffers) {
        this.applications = applications;
        this.jobOffers = jobOffers;
    }

    public List<Application> listForRecruiter(UUID jobOfferId, UUID recruiterId,
                                               ApplicationStatus status, int page, int size) {
        requireOwnedOffer(jobOfferId, recruiterId);
        return applications.findByJobOfferId(jobOfferId, status, page, size);
    }

    public Application getForActor(UUID applicationId, UUID actorId) {
        Application application = applications.findById(applicationId)
            .orElseThrow(() -> new NotFoundException("Candidature introuvable"));
        if (application.candidateId().equals(actorId)) {
            return application;
        }
        JobOffer offer = jobOffers.findById(application.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(actorId)) {
            throw new ForbiddenException("Cette candidature ne vous appartient pas");
        }
        return application;
    }

    private JobOffer requireOwnedOffer(UUID jobOfferId, UUID recruiterId) {
        JobOffer offer = jobOffers.findById(jobOfferId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        return offer;
    }
}
