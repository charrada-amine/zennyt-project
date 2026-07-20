package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Cas d'usage : créer une offre d'emploi (recruteur). */
@Service
@Transactional
public class CreateJobOfferUseCase {

    /** Commande de création — tous les champs descriptifs de l'offre. */
    public record Command(
        String title, String companyName, Location location, SalaryRange salary,
        ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
        String fieldOfWork, String description, String responsibilities,
        String minimumQualifications, String preferredQualifications,
        String whatWeOffer, String howToApply, String companyInfo,
        UUID assessmentId, UUID jobPositionId, int passingScore, boolean openToInternational
    ) {}

    private final JobOfferRepository repository;
    private final AssessmentRepository assessmentRepository;
    private final JobPositionRepository jobPositionRepository;
    private final ApplicationEventPublisher eventPublisher;

    public CreateJobOfferUseCase(JobOfferRepository repository,
                                 AssessmentRepository assessmentRepository,
                                 JobPositionRepository jobPositionRepository,
                                 ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.assessmentRepository = assessmentRepository;
        this.jobPositionRepository = jobPositionRepository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID recruiterId, Command cmd) {
        if (cmd.assessmentId() != null) {
            var assessment = assessmentRepository.findById(cmd.assessmentId())
                .orElseThrow(() -> new NotFoundException(
                    "Évaluation inexistante : " + cmd.assessmentId()));
            if (!assessment.createdByRecruiterId().equals(recruiterId)) {
                throw new ForbiddenException("Cette évaluation appartient à un autre recruteur");
            }
        }
        if (cmd.jobPositionId() != null) {
            jobPositionRepository.findById(cmd.jobPositionId())
                .orElseThrow(() -> new NotFoundException("Métier inexistant : " + cmd.jobPositionId()));
        }
        JobOffer offer = JobOffer.create(recruiterId, cmd.title(), cmd.description(),
            cmd.contractType(), cmd.workplaceType(), cmd.experienceLevel(), cmd.location(),
            cmd.passingScore());
        offer.update(cmd.title(), cmd.companyName(), cmd.location(), cmd.salary(),
            cmd.contractType(), cmd.workplaceType(), cmd.experienceLevel(), cmd.fieldOfWork(),
            cmd.description(), cmd.responsibilities(), cmd.minimumQualifications(),
            cmd.preferredQualifications(), cmd.whatWeOffer(), cmd.howToApply(), cmd.companyInfo(),
            cmd.assessmentId(), cmd.jobPositionId(), cmd.openToInternational());
        // Contrat frontend : une offre créée est immédiatement publiée, avec
        // status et postedAt imposés par le serveur (jamais par le client).
        offer.changeStatus(JobOfferStatus.ACTIVE);
        JobOffer saved = repository.save(offer);
        offer.domainEvents().forEach(eventPublisher::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
