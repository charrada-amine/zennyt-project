package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort.GenerationSpec;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.vo.AssessmentGenerationMode;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Cas d'usage : générer une évaluation MCQ par IA à partir d'une description
 * libre du poste/domaine ("From Prompt"), puis la persister
 * ({@code generationSource = FROM_PROMPT}).
 *
 * <p>Le recruteur relit et ajuste ensuite via le PUT existant — la génération
 * produit un brouillon complet, pas une vérité absolue.
 */
@Service
public class GenerateAssessmentFromPromptUseCase {

    public static final int MIN_QUESTIONS = 1;
    public static final int MAX_QUESTIONS = 30;
    public static final int MAX_DESCRIPTION_LENGTH = 1000;

    private final AssessmentGeneratorPort generator;
    private final AssessmentRepository repository;

    public GenerateAssessmentFromPromptUseCase(AssessmentGeneratorPort generator,
                                               AssessmentRepository repository) {
        this.generator = generator;
        this.repository = repository;
    }

    public record Command(String jobDescription, Integer questionCount) {}

    public Assessment execute(UUID recruiterId, Command cmd) {
        if (cmd.jobDescription() == null || cmd.jobDescription().isBlank()) {
            throw new IllegalArgumentException("La description du poste est obligatoire");
        }
        if (cmd.jobDescription().length() > MAX_DESCRIPTION_LENGTH) {
            throw new IllegalArgumentException(
                "La description ne doit pas dépasser " + MAX_DESCRIPTION_LENGTH + " caractères");
        }
        int count = validateCount(cmd.questionCount());

        List<AssessmentQuestion> questions = generator.generate(
            new GenerationSpec(cmd.jobDescription().trim(), count, "fr"));
        if (questions == null || questions.isEmpty()) {
            throw new UpstreamServiceException("L'IA n'a produit aucune question — réessayez");
        }

        Assessment assessment = Assessment.createFromGeneration(
            recruiterId, deriveTitle(cmd.jobDescription()), AssessmentGenerationMode.FROM_PROMPT, questions.size());
        assessment.applyGeneratedQuestions(questions);
        return repository.save(assessment);
    }

    private static int validateCount(Integer questionCount) {
        if (questionCount == null || questionCount < MIN_QUESTIONS || questionCount > MAX_QUESTIONS) {
            throw new IllegalArgumentException(
                "questionCount doit être entre " + MIN_QUESTIONS + " et " + MAX_QUESTIONS);
        }
        return questionCount;
    }

    private static String deriveTitle(String description) {
        String trimmed = description.trim().replaceAll("\\s+", " ");
        String snippet = trimmed.length() > 40 ? trimmed.substring(0, 40).trim() + "…" : trimmed;
        return "Test IA — " + snippet;
    }
}
