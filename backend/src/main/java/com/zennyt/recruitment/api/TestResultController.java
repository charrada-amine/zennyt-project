package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.PageResponse;
import com.zennyt.recruitment.api.dto.TestResultResponse;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.GetTestResultsUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.TestAnswer;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Contrôleur REST pour les résultats de test de compétences (contrat squad
 * web §7.2) — lecture seule, aucune écriture directe.
 */
@RestController
@RequestMapping("/api/v1/job-offers/{jobId}/test-results")
public class TestResultController {

    private final GetTestResultsUseCase useCase;
    private final RecruitmentActorRepository actors;
    private final AssessmentRepository assessments;

    public TestResultController(GetTestResultsUseCase useCase, RecruitmentActorRepository actors,
                                AssessmentRepository assessments) {
        this.useCase = useCase;
        this.actors = actors;
        this.assessments = assessments;
    }

    record CandidateSummary(UUID id, String fullName, String avatarUrl) {}
    record TestResultListItem(UUID id, CandidateSummary candidate, int score, int percentage,
                              boolean passed, int duration, TestResultStatus status, Instant completedAt) {}
    record SummaryResponse(long candidateCount, long passedCount, int successRate) {}
    record AnswerBreakdownItem(UUID questionId, String questionText, String selectedAnswer,
                               String correctAnswer, boolean isCorrect) {}
    record TestResultDetailResponse(UUID id, CandidateSummary candidate, int score, int percentage,
                                    boolean passed, Instant startedAt, Instant completedAt, int duration,
                                    TestResultStatus status, List<AnswerBreakdownItem> answerBreakdown) {}

    /** GET .../test-results/me — Résultat du candidat connecté pour cette offre. */
    @GetMapping("/me")
    @CandidateOrStudentOnly
    public ResponseEntity<TestResultResponse> myResult(@PathVariable UUID jobId, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        return useCase.getOwnResult(candidateId, jobId)
            .map(r -> ResponseEntity.ok(TestResultResponse.from(r)))
            .orElse(ResponseEntity.notFound().build());
    }

    /** GET .../test-results — Résultats paginés pour cette offre (recruteur, propriétaire). */
    @GetMapping
    @RecruiterOnly
    public ResponseEntity<PageResponse<TestResultListItem>> listForJob(@PathVariable UUID jobId,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        List<TestResult> results = useCase.listForJob(recruiterId, jobId, page, size);
        long totalElements = useCase.countForJob(recruiterId, jobId);
        var items = results.stream().map(this::toListItem).toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, totalElements));
    }

    /** GET .../test-results/summary — Agrégat sur l'ensemble complet (recruteur, propriétaire). */
    @GetMapping("/summary")
    @RecruiterOnly
    public ResponseEntity<SummaryResponse> summary(@PathVariable UUID jobId, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var summary = useCase.summaryForJob(recruiterId, jobId);
        return ResponseEntity.ok(new SummaryResponse(
            summary.candidateCount(), summary.passedCount(), summary.successRate()));
    }

    /** GET .../test-results/{candidateId} — Détail avec correction par question (recruteur, propriétaire). */
    @GetMapping("/{candidateId}")
    @RecruiterOnly
    public ResponseEntity<TestResultDetailResponse> detail(@PathVariable UUID jobId,
            @PathVariable UUID candidateId, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        TestResult result = useCase.detailForCandidate(recruiterId, jobId, candidateId);
        Assessment assessment = assessments.findById(result.hardSkillTestId())
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable"));
        Map<UUID, AssessmentQuestion> byId = assessment.questions().stream()
            .collect(Collectors.toMap(AssessmentQuestion::id, Function.identity()));
        List<AnswerBreakdownItem> breakdown = result.answers().stream()
            .map(a -> toBreakdownItem(a, byId.get(a.questionId())))
            .toList();
        return ResponseEntity.ok(new TestResultDetailResponse(result.id(), candidateSummary(candidateId),
            result.score(), result.percentage(), result.passed(), result.startedAt(), result.completedAt(),
            result.duration(), result.status(), breakdown));
    }

    private TestResultListItem toListItem(TestResult r) {
        return new TestResultListItem(r.id(), candidateSummary(r.candidateId()), r.score(), r.percentage(),
            r.passed(), r.duration(), r.status(), r.completedAt());
    }

    private CandidateSummary candidateSummary(UUID candidateId) {
        var actor = actors.findById(candidateId);
        return new CandidateSummary(candidateId,
            actor.map(a -> a.fullName()).orElse(null), actor.map(a -> a.avatarUrl()).orElse(null));
    }

    private AnswerBreakdownItem toBreakdownItem(TestAnswer answer, AssessmentQuestion question) {
        if (question == null) {
            return new AnswerBreakdownItem(answer.questionId(), null, null, null, answer.correct());
        }
        String selected = answer.selectedOptionIndex() >= 0 && answer.selectedOptionIndex() < question.options().size()
            ? question.options().get(answer.selectedOptionIndex()) : null;
        return new AnswerBreakdownItem(answer.questionId(), question.text(), selected,
            question.options().get(question.correctOptionIndex()), answer.correct());
    }
}
