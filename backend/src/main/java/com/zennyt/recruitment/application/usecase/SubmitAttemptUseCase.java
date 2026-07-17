package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentAttempt;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Soumet un assessment et ouvre idempotemment la candidature associée. */
@Service
@Transactional
public class SubmitAttemptUseCase {

    public record Command(UUID candidateId, UUID assessmentId, UUID jobOfferId,
                          List<Integer> answers) {}
    public record Result(Application application, AssessmentAttempt attempt) {}

    private final AssessmentAttemptRepository attempts;
    private final AssessmentRepository assessments;
    private final JobOfferRepository offers;
    private final ApplicationRepository applications;
    private final ApplicationEventPublisher events;

    public SubmitAttemptUseCase(AssessmentAttemptRepository attempts,
                                AssessmentRepository assessments,
                                JobOfferRepository offers,
                                ApplicationRepository applications,
                                ApplicationEventPublisher events) {
        this.attempts = attempts;
        this.assessments = assessments;
        this.offers = offers;
        this.applications = applications;
        this.events = events;
    }

    public Result execute(Command command) {
        if (attempts.existsByCandidateIdAndAssessmentIdAndJobOfferId(
                command.candidateId(), command.assessmentId(), command.jobOfferId())) {
            throw new ConflictException("Vous avez déjà passé ce test pour cette offre");
        }
        Assessment assessment = assessments.findById(command.assessmentId())
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable"));
        JobOffer offer = offers.findById(command.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!command.assessmentId().equals(offer.assessmentId())) {
            throw new IllegalArgumentException("Cette évaluation n'est pas assignée à cette offre");
        }
        if (command.answers() == null) {
            throw new IllegalArgumentException("Les réponses sont obligatoires");
        }

        Application application = applications
            .findByCandidateIdAndJobOfferId(command.candidateId(), command.jobOfferId())
            .orElseGet(() -> {
                Application created = Application.submit(command.candidateId(), command.jobOfferId());
                Application saved = applications.save(created);
                created.domainEvents().forEach(events::publishEvent);
                created.clearEvents();
                return saved;
            });

        AssessmentAttempt attempt = AssessmentAttempt.submit(
            command.candidateId(), command.assessmentId(), command.jobOfferId(), application.id(),
            command.answers(), assessment.questions(), offer.passingScore());
        AssessmentAttempt saved = attempts.save(attempt);
        attempt.domainEvents().forEach(events::publishEvent);
        attempt.clearEvents();

        // PROVISOIRE — à valider (Q-B10) : un test réussi ne change pas encore
        // automatiquement le statut de la candidature.
        return new Result(application, saved);
    }
}
