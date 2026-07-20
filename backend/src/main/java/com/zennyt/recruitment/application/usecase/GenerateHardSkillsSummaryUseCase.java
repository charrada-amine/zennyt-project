package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : (re)générer le résumé IA "Hard Skills Summary" d'un candidat
 * pour une offre — combine son CV et le résultat de la tentative qui vient
 * d'être soumise. Déclenché par {@code AssessmentAttemptSubmittedEvent} — voir
 * décision du 20/07 : sans tentative, aucune ligne n'est persistée, la lecture
 * affiche son propre repli statique.
 */
@Service
public class GenerateHardSkillsSummaryUseCase {

    private final AssessmentAttemptRepository attempts;
    private final JobOfferRepository jobOffers;
    private final CvProfileProjectionRepository cvProfiles;
    private final ResumeSummaryGeneratorPort generator;
    private final HardSkillsSummaryRepository summaries;

    public GenerateHardSkillsSummaryUseCase(AssessmentAttemptRepository attempts,
                                            JobOfferRepository jobOffers,
                                            CvProfileProjectionRepository cvProfiles,
                                            ResumeSummaryGeneratorPort generator,
                                            HardSkillsSummaryRepository summaries) {
        this.attempts = attempts;
        this.jobOffers = jobOffers;
        this.cvProfiles = cvProfiles;
        this.generator = generator;
        this.summaries = summaries;
    }

    public void execute(UUID attemptId) {
        var attempt = attempts.findById(attemptId).orElse(null);
        if (attempt == null) return;
        var offer = jobOffers.findById(attempt.jobOfferId()).orElse(null);
        if (offer == null) return;
        String cvText = cvProfiles.findByCandidateId(attempt.candidateId())
            .map(CvProfileProjection::cvText).orElse("");

        var text = generator.generateHardSkillsSummary(offer.title(), cvText, attempt.score(), attempt.passed());
        UUID existingId = summaries.findByCandidateIdAndJobOfferId(attempt.candidateId(), attempt.jobOfferId())
            .map(HardSkillsSummary::id).orElse(null);
        HardSkillsSummary summary = existingId != null
            ? new HardSkillsSummary(existingId, attempt.candidateId(), attempt.jobOfferId(),
                text.fr(), text.en(), Instant.now())
            : HardSkillsSummary.create(attempt.candidateId(), attempt.jobOfferId(),
                text.fr(), text.en(), Instant.now());
        summaries.save(summary);
    }
}
