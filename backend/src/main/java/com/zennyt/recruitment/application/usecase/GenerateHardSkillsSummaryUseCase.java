package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : (re)générer le résumé IA "Hard Skills Summary" d'un candidat
 * pour une offre — combine son CV et le résultat du test qui vient d'être
 * soumis. Déclenché par {@code TestResultCompletedEvent} (COMPLETED/TIMEOUT
 * uniquement — jamais ABANDONED, rien de significatif à résumer) — voir
 * décision du 20/07 : sans résultat, aucune ligne n'est persistée, la lecture
 * affiche son propre repli statique.
 */
@Service
public class GenerateHardSkillsSummaryUseCase {

    private final TestResultRepository testResults;
    private final JobOfferRepository jobOffers;
    private final CvProfileProjectionRepository cvProfiles;
    private final ResumeSummaryGeneratorPort generator;
    private final HardSkillsSummaryRepository summaries;

    public GenerateHardSkillsSummaryUseCase(TestResultRepository testResults,
                                            JobOfferRepository jobOffers,
                                            CvProfileProjectionRepository cvProfiles,
                                            ResumeSummaryGeneratorPort generator,
                                            HardSkillsSummaryRepository summaries) {
        this.testResults = testResults;
        this.jobOffers = jobOffers;
        this.cvProfiles = cvProfiles;
        this.generator = generator;
        this.summaries = summaries;
    }

    public void execute(UUID testResultId) {
        var result = testResults.findById(testResultId).orElse(null);
        if (result == null) return;
        var offer = jobOffers.findById(result.jobOfferId()).orElse(null);
        if (offer == null) return;
        String cvText = cvProfiles.findByCandidateId(result.candidateId())
            .map(CvProfileProjection::cvText).orElse("");

        var text = generator.generateHardSkillsSummary(offer.title(), cvText, result.percentage(), result.passed());
        UUID existingId = summaries.findByCandidateIdAndJobOfferId(result.candidateId(), result.jobOfferId())
            .map(HardSkillsSummary::id).orElse(null);
        HardSkillsSummary summary = existingId != null
            ? new HardSkillsSummary(existingId, result.candidateId(), result.jobOfferId(),
                text.fr(), text.en(), Instant.now())
            : HardSkillsSummary.create(result.candidateId(), result.jobOfferId(),
                text.fr(), text.en(), Instant.now());
        summaries.save(summary);
    }
}
