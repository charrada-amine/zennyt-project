package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.application.exception.UpstreamServiceException;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort;
import com.zennyt.recruitment.application.port.AssessmentGeneratorPort.GenerationSpec;
import com.zennyt.recruitment.application.port.SourceDocumentExtractorPort;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.vo.AssessmentGenerationMode;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Cas d'usage : générer une évaluation MCQ par IA à partir d'un fichier source
 * uploadé ("From File" — livre, manuel, MCQ existant…), puis la persister
 * ({@code generationSource = FROM_FILE}).
 *
 * <p>Le contrôleur (couche Api) lit les octets du {@code MultipartFile} et les
 * passe ici — l'extraction de texte reste derrière {@link SourceDocumentExtractorPort}
 * pour ne pas accrocher la couche application à PDFBox.
 */
@Service
public class GenerateAssessmentFromFileUseCase {

    public static final int MIN_QUESTIONS = 1;
    public static final int MAX_QUESTIONS = 30;
    static final long MAX_FILE_SIZE = 5L * 1024 * 1024;

    private final AssessmentGeneratorPort generator;
    private final SourceDocumentExtractorPort extractor;
    private final AssessmentRepository repository;

    public GenerateAssessmentFromFileUseCase(AssessmentGeneratorPort generator,
                                             SourceDocumentExtractorPort extractor,
                                             AssessmentRepository repository) {
        this.generator = generator;
        this.extractor = extractor;
        this.repository = repository;
    }

    public record Command(byte[] fileContent, String originalFilename, Integer questionCount) {}

    public Assessment execute(UUID recruiterId, Command cmd) {
        if (cmd.fileContent() == null || cmd.fileContent().length == 0) {
            throw new IllegalArgumentException("Le fichier est obligatoire");
        }
        if (cmd.fileContent().length > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Le fichier dépasse la limite de 5 Mo");
        }
        int count = validateCount(cmd.questionCount());

        String sourceText = extractor.extractText(cmd.fileContent());
        List<AssessmentQuestion> questions = generator.generate(new GenerationSpec(sourceText, count, "fr"));
        if (questions == null || questions.isEmpty()) {
            throw new UpstreamServiceException("L'IA n'a produit aucune question — réessayez");
        }

        Assessment assessment = Assessment.createFromGeneration(
            recruiterId, deriveTitle(cmd.originalFilename()), AssessmentGenerationMode.FROM_FILE, questions.size());
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

    private static String deriveTitle(String originalFilename) {
        if (originalFilename == null || originalFilename.isBlank()) return "Test IA — fichier";
        int dot = originalFilename.lastIndexOf('.');
        String base = dot > 0 ? originalFilename.substring(0, dot) : originalFilename;
        return base.trim();
    }
}
