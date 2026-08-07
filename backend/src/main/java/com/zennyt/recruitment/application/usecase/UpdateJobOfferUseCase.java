package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.JobOfferStatus;
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
 * <p>Contrat squad web §3 : PATCH ne touche que {@code status} et/ou
 * {@code assessmentId}, tout autre champ passe par PUT (voir
 * {@link ReplaceJobOfferUseCase}). {@code assessmentId} suit une sémantique à
 * trois états : {@code null} = inchangé, {@code Optional.empty()} =
 * désassigner, {@code Optional.of(x)} = assigner x.
 */
@Service
@Transactional
public class UpdateJobOfferUseCase {

    /** Commande de mise à jour partielle — status et/ou assessmentId, le reste est absent du DTO. */
    public record Command(Optional<UUID> assessmentId, JobOfferStatus status) {}

    private final JobOfferRepository repository;
    private final AssessmentRepository assessmentRepository;
    private final ApplicationEventPublisher eventPublisher;

    public UpdateJobOfferUseCase(JobOfferRepository repository,
                                 AssessmentRepository assessmentRepository,
                                 ApplicationEventPublisher eventPublisher) {
        this.repository = repository;
        this.assessmentRepository = assessmentRepository;
        this.eventPublisher = eventPublisher;
    }

    public JobOffer execute(UUID offerId, UUID recruiterId, Command cmd) {
        JobOffer offer = repository.findById(offerId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable : " + offerId));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre appartient à un autre recruteur");
        }

        if (cmd.assessmentId() != null) {
            UUID assessmentId = cmd.assessmentId().orElse(null);
            if (assessmentId != null) {
                var assessment = assessmentRepository.findById(assessmentId)
                    .orElseThrow(() -> new NotFoundException(
                        "Évaluation inexistante : " + assessmentId));
                if (!assessment.createdByRecruiterId().equals(recruiterId)) {
                    throw new ForbiddenException(
                        "Cette évaluation appartient à un autre recruteur");
                }
            }
            offer.assignAssessment(assessmentId);
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
