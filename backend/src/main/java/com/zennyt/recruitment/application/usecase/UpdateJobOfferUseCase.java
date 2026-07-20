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

import java.util.Optional;
import java.util.UUID;

/**
 * Cas d'usage : mise à jour partielle d'une offre (PATCH).
 *
 * <p>Chaque champ {@code null} de la commande est laissé inchangé.
 * {@code assessmentId} suit une sémantique à trois états : {@code null} =
 * inchangé, {@code Optional.empty()} = désassigner, {@code Optional.of(x)} =
 * assigner x. Le merge est fait ici, côté serveur, dans une transaction —
 * le client n'a plus besoin du GET+PUT en deux temps.
 */
@Service
@Transactional
public class UpdateJobOfferUseCase {

    /** Commande de mise à jour partielle. */
    public record Command(
        String title, String companyName,
        String city, String country, Boolean remote,
        Double salaryMin, Double salaryMax, String currency,
        ContractType contractType, WorkplaceType workplaceType, ExperienceLevel experienceLevel,
        String fieldOfWork, String description, String responsibilities,
        String minimumQualifications, String preferredQualifications,
        String whatWeOffer, String howToApply, String companyInfo,
        Optional<UUID> assessmentId, UUID jobPositionId, Integer passingScore, Boolean openToInternational,
        JobOfferStatus status
    ) {}

    private final JobOfferRepository repository;
    private final AssessmentRepository assessmentRepository;
    private final JobPositionRepository jobPositionRepository;
    private final ApplicationEventPublisher eventPublisher;

    public UpdateJobOfferUseCase(JobOfferRepository repository,
                                 AssessmentRepository assessmentRepository,
                                 JobPositionRepository jobPositionRepository,
                                 ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.assessmentRepository = assessmentRepository;
        this.jobPositionRepository = jobPositionRepository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID offerId, UUID recruiterId, Command cmd) {
        JobOffer offer = repository.findById(offerId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable : " + offerId));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre appartient à un autre recruteur");
        }

        UUID assessmentId = offer.assessmentId();
        if (cmd.assessmentId() != null) {
            assessmentId = cmd.assessmentId().orElse(null);
            if (assessmentId != null) {
                UUID candidateAssessmentId = assessmentId;
                var assessment = assessmentRepository.findById(candidateAssessmentId)
                    .orElseThrow(() -> new NotFoundException(
                        "Évaluation inexistante : " + candidateAssessmentId));
                if (!assessment.createdByRecruiterId().equals(recruiterId)) {
                    throw new ForbiddenException(
                        "Cette évaluation appartient à un autre recruteur");
                }
            }
        }

        UUID jobPositionId = cmd.jobPositionId() != null ? cmd.jobPositionId() : offer.jobPositionId();
        if (cmd.jobPositionId() != null) {
            jobPositionRepository.findById(cmd.jobPositionId())
                .orElseThrow(() -> new NotFoundException("Métier inexistant : " + cmd.jobPositionId()));
        }

        Location loc = offer.location();
        Location location = new Location(
            cmd.city() != null ? cmd.city() : (loc != null ? loc.city() : null),
            cmd.country() != null ? cmd.country() : (loc != null ? loc.country() : null),
            cmd.remote() != null ? cmd.remote() : (loc != null && loc.remote()));

        SalaryRange sal = offer.salary();
        Double min = cmd.salaryMin() != null ? cmd.salaryMin() : (sal != null ? sal.min() : null);
        Double max = cmd.salaryMax() != null ? cmd.salaryMax() : (sal != null ? sal.max() : null);
        String currency = cmd.currency() != null ? cmd.currency() : (sal != null ? sal.currency() : null);
        SalaryRange salary = (min != null && max != null && currency != null)
            ? new SalaryRange(min, max, currency) : null;

        offer.update(
            cmd.title() != null ? cmd.title() : offer.title(),
            cmd.companyName() != null ? cmd.companyName() : offer.companyName(),
            location, salary,
            cmd.contractType() != null ? cmd.contractType() : offer.contractType(),
            cmd.workplaceType() != null ? cmd.workplaceType() : offer.workplaceType(),
            cmd.experienceLevel() != null ? cmd.experienceLevel() : offer.experienceLevel(),
            cmd.fieldOfWork() != null ? cmd.fieldOfWork() : offer.fieldOfWork(),
            cmd.description() != null ? cmd.description() : offer.description(),
            cmd.responsibilities() != null ? cmd.responsibilities() : offer.responsibilities(),
            cmd.minimumQualifications() != null ? cmd.minimumQualifications() : offer.minimumQualifications(),
            cmd.preferredQualifications() != null ? cmd.preferredQualifications() : offer.preferredQualifications(),
            cmd.whatWeOffer() != null ? cmd.whatWeOffer() : offer.whatWeOffer(),
            cmd.howToApply() != null ? cmd.howToApply() : offer.howToApply(),
            cmd.companyInfo() != null ? cmd.companyInfo() : offer.companyInfo(),
            assessmentId, jobPositionId,
            cmd.openToInternational() != null ? cmd.openToInternational() : offer.openToInternational());
        if (cmd.passingScore() != null) {
            offer.setPassingScore(cmd.passingScore());
        }

        if (cmd.status() != null && cmd.status() != offer.status()) {
            offer.changeStatus(cmd.status());
        }

        JobOffer saved = repository.save(offer);
        offer.domainEvents().forEach(eventPublisher::publishEvent);
        offer.clearEvents();
        return saved;
    }
}
