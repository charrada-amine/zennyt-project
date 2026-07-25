package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.port.ResumeSummaryGeneratorPort;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.model.SoftSkillsSummary;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsSummaryRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Cas d'usage : (re)générer le résumé IA "Soft Skills Summary" d'un candidat
 * à partir de ses scores par module psychométrique — candidat-level, réutilisé
 * pour toutes les offres (voir décision du 20/07).
 *
 * <p>Ne fait rien si le candidat n'a encore joué aucun module : la lecture
 * affiche alors son propre repli statique, pas la peine d'appeler l'IA.
 */
@Service
public class GenerateSoftSkillsSummaryUseCase {

    /** Libellés lisibles des modules Games (déclarés ici pour ne pas dépendre de games.domain.vo.GameType). */
    private static final Map<String, String> MODULE_LABELS = Map.of(
        "MOVE_FAST", "Cognitive flexibility",
        "MEMORY_QUEST", "Working memory",
        "PLANIFIK", "Executive planning",
        "DECISION", "Decision making"
    );

    private final SoftSkillsProjectionRepository projections;
    private final ResumeSummaryGeneratorPort generator;
    private final SoftSkillsSummaryRepository summaries;

    public GenerateSoftSkillsSummaryUseCase(SoftSkillsProjectionRepository projections,
                                            ResumeSummaryGeneratorPort generator,
                                            SoftSkillsSummaryRepository summaries) {
        this.projections = projections;
        this.generator = generator;
        this.summaries = summaries;
    }

    public void execute(UUID candidateId) {
        var modules = projections.findByCandidateId(candidateId);
        if (modules.isEmpty()) return;

        Map<String, Integer> scores = modules.stream().collect(Collectors.toMap(
            m -> MODULE_LABELS.getOrDefault(m.module(), m.module()),
            SoftSkillsProjection::score,
            (left, right) -> right));

        var text = generator.generateSoftSkillsSummary(scores);
        summaries.save(new SoftSkillsSummary(candidateId, text.fr(), text.en(), Instant.now()));
    }
}
