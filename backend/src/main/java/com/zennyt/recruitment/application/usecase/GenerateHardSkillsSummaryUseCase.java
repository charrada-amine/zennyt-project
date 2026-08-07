package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.model.CvProfileProjection;
import com.zennyt.recruitment.domain.model.HardSkillsSummary;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.CvProfileProjectionRepository;
import com.zennyt.recruitment.domain.repository.HardSkillsSummaryRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.HardSkillHistoryEntry;
import com.zennyt.recruitment.domain.vo.HardSkillTrend;
import com.zennyt.recruitment.domain.vo.ResumeAudience;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Cas d'usage : (re)générer le résumé IA "Hard Skills Summary" d'un candidat sur un
 * <b>métier</b> — combine son CV et l'historique de ses tests techniques sur ce métier.
 * Déclenché par {@code TestResultCompletedEvent} (COMPLETED/TIMEOUT uniquement — jamais
 * ABANDONED, rien de significatif à résumer).
 *
 * <p><b>D1 — le résumé n'est plus par offre.</b> Le rester aurait produit N textes
 * identiques pour N offres du même métier, chacun régénéré et facturé séparément à chaque
 * test.
 *
 * <p><b>Une différence assumée avec le Fit Score</b> : le résumé n'ayant pas d'offre, il ne
 * peut pas appliquer la règle « le test de l'offre consultée au rang 1 » (D3) et n'affiche
 * donc aucun score agrégé — c'est le générateur qui en a la consigne. Les deux vues
 * reposent bien sur <b>les mêmes résultats</b> ; seul le Fit Score en tire un nombre, parce
 * que lui seul sait de quelle offre on parle.
 *
 * <p>Les deux publics sont générés dans la foulée (P5) : deux appels au modèle, mais un
 * seul chargement du CV et de l'historique.
 */
@Service
public class GenerateHardSkillsSummaryUseCase {

    private final TestResultRepository testResults;
    private final JobOfferRepository jobOffers;
    private final JobPositionRepository jobPositions;
    private final CvProfileProjectionRepository cvProfiles;
    private final ResumeSummaryGeneratorPort generator;
    private final HardSkillsSummaryRepository summaries;

    public GenerateHardSkillsSummaryUseCase(TestResultRepository testResults,
                                            JobOfferRepository jobOffers,
                                            JobPositionRepository jobPositions,
                                            CvProfileProjectionRepository cvProfiles,
                                            ResumeSummaryGeneratorPort generator,
                                            HardSkillsSummaryRepository summaries) {
        this.testResults = testResults;
        this.jobOffers = jobOffers;
        this.jobPositions = jobPositions;
        this.cvProfiles = cvProfiles;
        this.generator = generator;
        this.summaries = summaries;
    }

    public void execute(UUID testResultId) {
        var result = testResults.findById(testResultId).orElse(null);
        if (result == null) return;
        var offer = jobOffers.findById(result.jobOfferId()).orElse(null);
        if (offer == null || offer.jobPositionId() == null) return;
        UUID jobPositionId = offer.jobPositionId();

        List<HardSkillHistoryEntry> history =
            testResults.findHardSkillHistory(result.candidateId(), jobPositionId);
        // Peut arriver si le résultat vient d'être abandonné : rien de noté à résumer.
        if (history.isEmpty()) return;

        String cvText = cvProfiles.findByCandidateId(result.candidateId())
            .map(CvProfileProjection::cvText).orElse("");
        // Le nom du métier, pas le titre de l'offre : le résumé couvre désormais le métier.
        String jobPositionName = jobPositions.findById(jobPositionId)
            .map(JobPosition::name).orElse(offer.title());
        List<ResumeSummaryGeneratorPort.HardSkillTestRecap> recaps = history.stream()
            .map(entry -> new ResumeSummaryGeneratorPort.HardSkillTestRecap(
                entry.percentage(), entry.passed(), entry.completedAt(), entry.experienceLevel()))
            .toList();
        // La direction de la trajectoire est établie ici, par comparaison d'entiers, et
        // transmise comme un fait. La laisser déduire au modèle l'a fait annoncer une
        // progression à un candidat en baisse — voir HardSkillTrend.
        var context = new ResumeSummaryGeneratorPort.HardSkillsContext(
            jobPositionName, cvText, recaps, HardSkillTrend.of(history));

        for (ResumeAudience audience : ResumeAudience.values()) {
            var text = generator.generateHardSkillsSummary(context, audience);
            UUID existingId = summaries
                .findByCandidateIdAndJobPositionIdAndAudience(result.candidateId(), jobPositionId, audience)
                .map(HardSkillsSummary::id).orElse(null);
            summaries.save(existingId != null
                ? new HardSkillsSummary(existingId, result.candidateId(), jobPositionId, audience,
                    text.fr(), text.en(), Instant.now())
                : HardSkillsSummary.create(result.candidateId(), jobPositionId, audience,
                    text.fr(), text.en(), Instant.now()));
        }
    }
}
