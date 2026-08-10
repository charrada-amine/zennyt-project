package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : créer une offre d'emploi (recruteur). */
@Service
@Transactional
public class CreateJobOfferUseCase {

    /**
     * Commande de création — tous les champs descriptifs de l'offre.
     *
     * <p>F23 (FITSCORE_REMEDIATION.md §3 index F23) — pas de champ {@code
     * assessmentId} : le contrat squad web §3.3 réserve volontairement
     * l'assignation d'une évaluation au PATCH ({@link UpdateJobOfferUseCase}),
     * jamais à la création. Un champ ici serait mort par construction (le
     * contrôleur n'a aucune source pour le remplir) et suggérerait une
     * capacité non câblée.
     */
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

    public CreateJobOfferUseCase(JobOfferRepository repository,
                                 JobPositionRepository jobPositionRepository,
                                 ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.jobPositionRepository = jobPositionRepository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID recruiterId, Command cmd) {
        // Obligatoire depuis la suppression du repli IA : sans métier, la formule n'a
        // pas de pondération et l'offre resterait sans Fit Score. Le recruteur choisit
        // un métier du référentiel, ou en propose un nouveau (ProposeJobPositionUseCase),
        // immédiatement utilisable en attente d'approbation.
        if (cmd.jobPositionId() == null) {
            throw new IllegalArgumentException("Le métier (jobPositionId) est obligatoire");
        }
        jobPositionRepository.findById(cmd.jobPositionId())
            .orElseThrow(() -> new NotFoundException("Métier inexistant : " + cmd.jobPositionId()));
        JobOffer offer = JobOffer.create(recruiterId, cmd.title(), cmd.description(),
            cmd.contractType(), cmd.workplaceType(), cmd.experienceLevel(), cmd.location());
        offer.update(cmd.title(), cmd.location(), cmd.salaryMin(), cmd.salaryMax(),
            cmd.contractType(), cmd.workplaceType(), cmd.experienceLevel(),
            cmd.description(), cmd.responsibilities(), cmd.minimumQualifications(),
            cmd.preferredQualifications(), cmd.whatWeOffer(), cmd.howToApply(),
            null, cmd.jobPositionId(), cmd.openToInternational());
        // Contrat frontend : une offre créée est immédiatement publiée, avec
        // status et postedAt imposés par le serveur (jamais par le client).
        offer.changeStatus(JobOfferStatus.ACTIVE);
        JobOffer saved = repository.save(offer);
        offer.domainEvents().forEach(eventPublisher::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
