package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Cas d'usage : remplacement complet d'une offre (PUT).
 *
 * <p>Contrairement à PATCH, un champ optionnel absent du corps est réinitialisé
 * (pas de fusion avec l'existant) — {@code status} et {@code assessmentId} ne
 * sont pas touchés (server-owned / gérés par PATCH), voir contrat squad web §3.
 */
@Service
@Transactional
public class ReplaceJobOfferUseCase {

    public record Command(
        String title, Location location, Double salaryMin, Double salaryMax,
        ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
        String description, String responsibilities,
        String minimumQualifications, String preferredQualifications,
        String whatWeOffer, String howToApply,
        UUID jobPositionId, boolean openToInternational
    ) {}

    private final JobOfferRepository repository;
    private final JobPositionRepository jobPositionRepository;
    private final ApplicationEventPublisher eventPublisher;

    public ReplaceJobOfferUseCase(JobOfferRepository repository,
                                  JobPositionRepository jobPositionRepository,
                                  ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.jobPositionRepository = jobPositionRepository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID offerId, UUID recruiterId, Command cmd) {
        JobOffer offer = repository.findById(offerId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable : " + offerId));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre appartient à un autre recruteur");
        }
        if (cmd.jobPositionId() != null) {
            jobPositionRepository.findById(cmd.jobPositionId())
                .orElseThrow(() -> new NotFoundException("Métier inexistant : " + cmd.jobPositionId()));
        }
        offer.update(cmd.title(), cmd.location(), cmd.salaryMin(), cmd.salaryMax(),
            cmd.contractType(), cmd.workplaceType(), cmd.experienceLevel(),
            cmd.description(), cmd.responsibilities(), cmd.minimumQualifications(),
            cmd.preferredQualifications(), cmd.whatWeOffer(), cmd.howToApply(),
            offer.assessmentId(), cmd.jobPositionId(), cmd.openToInternational());
        JobOffer saved = repository.save(offer);
        offer.domainEvents().forEach(eventPublisher::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
