package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.TestResultResponse;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.application.usecase.AbandonTestAttemptUseCase;
import com.zennyt.recruitment.application.usecase.StartTestAttemptUseCase;
import com.zennyt.recruitment.application.usecase.SubmitTestAttemptUseCase;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.PresentedQuestion;
import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Contrôleur REST pour les tentatives de test de compétences (contrat squad
 * web §7.2). Le mécanisme de mélange n'est jamais exposé : les questions
 * reviennent dans leur ordre de présentation, options mélangées, sans
 * {@code correctOptionIndex}.
 */
@RestController
@RequestMapping("/api/v1")
public class TestAttemptController {

    private final StartTestAttemptUseCase startUseCase;
    private final SubmitTestAttemptUseCase submitUseCase;
    private final AbandonTestAttemptUseCase abandonUseCase;
    private final AssessmentRepository assessments;

    public TestAttemptController(StartTestAttemptUseCase startUseCase, SubmitTestAttemptUseCase submitUseCase,
                                 AbandonTestAttemptUseCase abandonUseCase, AssessmentRepository assessments) {
        this.startUseCase = startUseCase;
        this.submitUseCase = submitUseCase;
        this.abandonUseCase = abandonUseCase;
        this.assessments = assessments;
    }

    record PresentedQuestionResponse(UUID id, int order, String text, List<String> options) {}
    record StartAttemptResponse(UUID attemptId, UUID jobOfferId, int timeLimitSeconds,
                                Instant expiresAt, List<PresentedQuestionResponse> questions) {}

    record AnswerRequest(UUID questionId, int selectedOptionIndex) {}
    record SubmitRequest(List<AnswerRequest> answers) {}

    /** POST /api/v1/job-offers/{jobId}/test-attempts — Démarrer la tentative (candidat). */
    @PostMapping("/job-offers/{jobId}/test-attempts")
    @CandidateOrStudentOnly
    public ResponseEntity<StartAttemptResponse> start(@PathVariable UUID jobId, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        TestAttempt attempt = startUseCase.execute(candidateId, jobId);
        Assessment assessment = assessments.findById(attempt.hardSkillTestId())
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable"));
        int timeLimitSeconds = (int) Duration.between(attempt.startedAt(), attempt.expiresAt()).getSeconds();
        return ResponseEntity.status(HttpStatus.CREATED).body(new StartAttemptResponse(
            attempt.id(), attempt.jobOfferId(), timeLimitSeconds, attempt.expiresAt(),
            presentedView(attempt, assessment)));
    }

    /** POST /api/v1/test-attempts/{attemptId}/submit — Soumettre les réponses (candidat, propriétaire). */
    @PostMapping("/test-attempts/{attemptId}/submit")
    @CandidateOrStudentOnly
    public ResponseEntity<TestResultResponse> submit(@PathVariable UUID attemptId,
            @RequestBody SubmitRequest req, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        var answers = req.answers().stream()
            .map(a -> new SubmitTestAttemptUseCase.AnswerInput(a.questionId(), a.selectedOptionIndex()))
            .toList();
        var result = submitUseCase.execute(candidateId, attemptId, answers);
        return ResponseEntity.ok(TestResultResponse.from(result));
    }

    /** POST /api/v1/test-attempts/{attemptId}/abandon — Abandon explicite (candidat, propriétaire). */
    @PostMapping("/test-attempts/{attemptId}/abandon")
    @CandidateOrStudentOnly
    public ResponseEntity<TestResultResponse> abandon(@PathVariable UUID attemptId, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        var result = abandonUseCase.execute(candidateId, attemptId);
        return ResponseEntity.ok(TestResultResponse.from(result));
    }

    private List<PresentedQuestionResponse> presentedView(TestAttempt attempt, Assessment assessment) {
        Map<UUID, AssessmentQuestion> byId = assessment.questions().stream()
            .collect(Collectors.toMap(AssessmentQuestion::id, Function.identity()));
        return attempt.presentedQuestions().stream()
            .sorted((a, b) -> Integer.compare(a.order(), b.order()))
            .map(pq -> toResponse(pq, byId.get(pq.questionId())))
            .toList();
    }

    private PresentedQuestionResponse toResponse(PresentedQuestion pq, AssessmentQuestion original) {
        List<String> shuffledOptions = pq.optionOrder().stream().map(idx -> original.options().get(idx)).toList();
        return new PresentedQuestionResponse(pq.questionId(), pq.order(), original.text(), shuffledOptions);
    }
}
