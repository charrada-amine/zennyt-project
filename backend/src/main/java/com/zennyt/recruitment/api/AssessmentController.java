package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.PageResponse;
import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.GenerateAssessmentFromFileUseCase;
import com.zennyt.recruitment.application.usecase.GenerateAssessmentFromPromptUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Contrôleur REST pour les évaluations (tests créés par le recruteur). */
@RestController
@RequestMapping("/api/v1/assessments")
public class AssessmentController {

    private final AssessmentRepository assessmentRepository;
    private final JobOfferRepository jobOfferRepository;
    private final GenerateAssessmentFromPromptUseCase generateFromPromptUseCase;
    private final GenerateAssessmentFromFileUseCase generateFromFileUseCase;

    public AssessmentController(AssessmentRepository assessmentRepository,
                                JobOfferRepository jobOfferRepository,
                                GenerateAssessmentFromPromptUseCase generateFromPromptUseCase,
                                GenerateAssessmentFromFileUseCase generateFromFileUseCase) {
        this.assessmentRepository = assessmentRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.generateFromPromptUseCase = generateFromPromptUseCase;
        this.generateFromFileUseCase = generateFromFileUseCase;
    }

    record CreateAssessmentRequest(String title, Integer timeLimitSeconds, List<QuestionDto> questions) {}
    record UpdateAssessmentRequest(String title, Integer timeLimitSeconds, List<QuestionDto> questions) {}

    /** L'{@code id} est optionnel en entrée : fourni, il préserve une question existante. */
    record QuestionDto(UUID id, Integer order, String text, List<String> options, Integer correctOptionIndex) {
        AssessmentQuestion toDomain() {
            if (correctOptionIndex == null) throw new IllegalArgumentException("correctOptionIndex est obligatoire");
            return new AssessmentQuestion(id, order != null ? order : 0, text, options, correctOptionIndex);
        }
        static QuestionDto from(AssessmentQuestion q) {
            return new QuestionDto(q.id(), q.order(), q.text(), q.options(), q.correctOptionIndex());
        }
    }

    record AssessmentResponse(UUID id, UUID recruiterId, String title, int timeLimitSeconds,
                              int maxQuestions, List<QuestionDto> questions,
                              Instant createdAt, Instant updatedAt, String shareableLink,
                              List<UUID> linkedJobOfferIds) {
        static AssessmentResponse from(Assessment a, List<UUID> linkedJobOfferIds) {
            return new AssessmentResponse(a.id(), a.createdByRecruiterId(), a.title(),
                a.timeLimitSeconds(), a.maxQuestions(),
                a.questions().stream().map(QuestionDto::from).toList(),
                a.createdAt(), a.updatedAt(), a.shareableLink(), linkedJobOfferIds);
        }
    }

    record AssessmentSummaryResponse(UUID id, String title, int timeLimitSeconds, int maxQuestions,
                                     int questionsCount, Instant createdAt, long linkedJobOffersCount) {
        static AssessmentSummaryResponse from(Assessment a, long linkedJobOffersCount) {
            return new AssessmentSummaryResponse(a.id(), a.title(), a.timeLimitSeconds(), a.maxQuestions(),
                a.questions().size(), a.createdAt(), linkedJobOffersCount);
        }
    }

    /** POST /api/v1/assessments — Créer une évaluation */
    @PostMapping
    @RecruiterOnly
    public ResponseEntity<AssessmentResponse> create(@RequestBody CreateAssessmentRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        if (req.questions() == null || req.questions().isEmpty()) {
            throw new IllegalArgumentException("Au moins une question est requise");
        }
        List<AssessmentQuestion> questions = req.questions().stream().map(QuestionDto::toDomain).toList();
        Assessment assessment = Assessment.createManual(recruiterId, req.title(),
            req.timeLimitSeconds() != null ? req.timeLimitSeconds() : 0, questions);
        Assessment saved = assessmentRepository.save(assessment);
        return ResponseEntity.status(HttpStatus.CREATED).body(AssessmentResponse.from(saved, List.of()));
    }

    record GenerateFromPromptRequest(String jobDescription, Integer questionCount) {}

    /**
     * POST /api/v1/assessments/generate/from-prompt — Générer un test par IA
     * à partir d'une description libre du poste/domaine.
     */
    @PostMapping("/generate/from-prompt")
    @RecruiterOnly
    public ResponseEntity<AssessmentResponse> generateFromPrompt(
            @RequestBody GenerateFromPromptRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Assessment saved = generateFromPromptUseCase.execute(recruiterId,
            new GenerateAssessmentFromPromptUseCase.Command(req.jobDescription(), req.questionCount()));
        return ResponseEntity.status(HttpStatus.CREATED).body(AssessmentResponse.from(saved, List.of()));
    }

    /**
     * POST /api/v1/assessments/generate/from-file — Générer un test par IA à
     * partir d'un fichier source uploadé (livre, manuel, MCQ existant…).
     */
    @PostMapping(value = "/generate/from-file", consumes = "multipart/form-data")
    @RecruiterOnly
    public ResponseEntity<AssessmentResponse> generateFromFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("questionCount") Integer questionCount,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la lecture du fichier", e);
        }
        Assessment saved = generateFromFileUseCase.execute(recruiterId,
            new GenerateAssessmentFromFileUseCase.Command(content, file.getOriginalFilename(), questionCount));
        return ResponseEntity.status(HttpStatus.CREATED).body(AssessmentResponse.from(saved, List.of()));
    }

    /** GET /api/v1/assessments — Évaluations du recruteur authentifié (vue résumée). */
    @GetMapping
    @RecruiterOnly
    public ResponseEntity<List<AssessmentSummaryResponse>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        List<Assessment> assessments = assessmentRepository.findByRecruiterId(recruiterId, page, size);
        Map<UUID, Long> linkedCounts = jobOfferRepository.countByAssessmentIds(
            assessments.stream().map(Assessment::id).toList());
        return ResponseEntity.ok(assessments.stream()
            .map(a -> AssessmentSummaryResponse.from(a, linkedCounts.getOrDefault(a.id(), 0L)))
            .toList());
    }

    /** GET /api/v1/assessments/{id} — Détail */
    @GetMapping("/{id}")
    @RecruiterOnly
    public ResponseEntity<AssessmentResponse> getById(@PathVariable UUID id, Principal principal) {
        Assessment assessment = assessmentRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable : " + id));
        if (!assessment.createdByRecruiterId().equals(UUID.fromString(principal.getName()))) {
            throw new ForbiddenException("Cette évaluation appartient à un autre recruteur");
        }
        return ResponseEntity.ok(AssessmentResponse.from(assessment, jobOfferRepository.findIdsByAssessmentId(id)));
    }

    /** GET /api/v1/assessments/mine — Mes évaluations (alias historique) */
    @GetMapping("/mine")
    @RecruiterOnly
    public ResponseEntity<PageResponse<AssessmentResponse>> myAssessments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        List<Assessment> assessments = assessmentRepository.findByRecruiterId(recruiterId, page, size);
        List<AssessmentResponse> content = assessments.stream()
            .map(a -> AssessmentResponse.from(a, jobOfferRepository.findIdsByAssessmentId(a.id())))
            .toList();
        long totalElements = assessmentRepository.countByRecruiterId(recruiterId);
        return ResponseEntity.ok(PageResponse.of(content, page, size, totalElements));
    }

    /**
     * PUT /api/v1/assessments/{id} — Mise à jour (title/timeLimitSeconds/questions optionnels).
     *
     * <p>Les questions envoyées avec leur {@code id} le conservent ; sans id,
     * une nouvelle question (id serveur) est créée. L'ordre est renuméroté.
     */
    @PutMapping("/{id}")
    @RecruiterOnly
    public ResponseEntity<AssessmentResponse> update(@PathVariable UUID id,
            @RequestBody UpdateAssessmentRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Assessment assessment = assessmentRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable : " + id));
        if (!assessment.createdByRecruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette évaluation appartient à un autre recruteur");
        }
        List<AssessmentQuestion> questions = req.questions() != null
            ? req.questions().stream().map(QuestionDto::toDomain).toList() : null;
        assessment.update(req.title(), req.timeLimitSeconds(), questions);
        Assessment saved = assessmentRepository.save(assessment);
        return ResponseEntity.ok(AssessmentResponse.from(saved, jobOfferRepository.findIdsByAssessmentId(id)));
    }

    /** DELETE /api/v1/assessments/{id} — Supprimer (409 si une offre la référence encore) */
    @DeleteMapping("/{id}")
    @RecruiterOnly
    public ResponseEntity<Void> delete(@PathVariable UUID id, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Assessment assessment = assessmentRepository.findById(id).orElse(null);
        if (assessment == null) {
            return ResponseEntity.noContent().build(); // suppression idempotente
        }
        if (!assessment.createdByRecruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette évaluation appartient à un autre recruteur");
        }
        List<UUID> linkedJobOfferIds = jobOfferRepository.findIdsByAssessmentId(id);
        if (!linkedJobOfferIds.isEmpty()) {
            throw new ConflictException("ASSESSMENT_IN_USE",
                "Cette évaluation est encore liée à " + linkedJobOfferIds.size()
                    + " offre(s) d'emploi — désassignez-la d'abord",
                Map.of("linkedJobOfferIds", linkedJobOfferIds));
        }
        assessmentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
