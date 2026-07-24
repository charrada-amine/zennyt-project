package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.TestAnswer;
import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.TestAttemptRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.TestAttemptStatus;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Cas d'usage : soumettre une tentative (contrat squad web §7.2-7.5).
 *
 * <p>{@code selectedOptionIndex} est démélangé via le mapping stocké sur la
 * tentative avant d'être comparé à la bonne réponse. Si la soumission arrive
 * après {@code expiresAt}, le statut devient {@code TIMEOUT} quoi qu'il
 * arrive — jamais {@code COMPLETED} — indépendamment de ce que le client
 * prétend.
 */
@Service
@Transactional
public class SubmitTestAttemptUseCase {

    public record AnswerInput(UUID questionId, int selectedOptionIndex) {}

    private final TestAttemptRepository testAttempts;
    private final TestResultRepository testResults;
    private final AssessmentRepository assessments;
    private final ApplicationEventPublisher events;

    public SubmitTestAttemptUseCase(TestAttemptRepository testAttempts, TestResultRepository testResults,
                                    AssessmentRepository assessments, ApplicationEventPublisher events) {
        this.testAttempts = testAttempts;
        this.testResults = testResults;
        this.assessments = assessments;
        this.events = events;
    }

    public TestResult execute(UUID candidateId, UUID attemptId, List<AnswerInput> answers) {
        TestAttempt attempt = testAttempts.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Tentative introuvable"));
        if (!attempt.candidateId().equals(candidateId)) {
            throw new ForbiddenException("Cette tentative ne vous appartient pas");
        }
        if (attempt.status() != TestAttemptStatus.IN_PROGRESS) {
            throw new ConflictException("ATTEMPT_ALREADY_SUBMITTED", "Cette tentative a déjà été soumise");
        }
        Assessment assessment = assessments.findById(attempt.hardSkillTestId())
            .orElseThrow(() -> new NotFoundException("Évaluation introuvable"));
        Map<UUID, Integer> correctByQuestion = assessment.questions().stream()
            .collect(Collectors.toMap(AssessmentQuestion::id, AssessmentQuestion::correctOptionIndex));

        List<TestAnswer> graded = answers.stream().map(a -> {
            int originalIndex = attempt.originalOptionIndex(a.questionId(), a.selectedOptionIndex());
            boolean correct = correctByQuestion.getOrDefault(a.questionId(), -1) == originalIndex;
            return new TestAnswer(a.questionId(), originalIndex, correct);
        }).toList();

        Instant now = Instant.now();
        TestResultStatus status = attempt.isExpired(now) ? TestResultStatus.TIMEOUT : TestResultStatus.COMPLETED;
        TestResult result = TestResult.complete(attempt.jobOfferId(), attempt.hardSkillTestId(), candidateId,
            graded, attempt.presentedQuestions().size(), attempt.startedAt(), now, status);
        TestResult saved = testResults.save(result);

        attempt.markResolved(TestAttemptStatus.SUBMITTED);
        testAttempts.save(attempt);

        saved.domainEvents().forEach(events::publishEvent);
        saved.clearEvents();
        return saved;
    }
}
