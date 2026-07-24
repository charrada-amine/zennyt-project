package com.zennyt.recruitment.application.usecase;

import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.TestAttemptRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import com.zennyt.recruitment.domain.vo.TestAttemptStatus;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Cas d'usage : abandon explicite d'une tentative (app fermée, retour
 * arrière — contrat squad web §7.2). Score 0, non réussi ; ne déclenche pas
 * la régénération du résumé IA hard skills (rien de significatif à résumer).
 */
@Service
@Transactional
public class AbandonTestAttemptUseCase {

    private final TestAttemptRepository testAttempts;
    private final TestResultRepository testResults;

    public AbandonTestAttemptUseCase(TestAttemptRepository testAttempts, TestResultRepository testResults) {
        this.testAttempts = testAttempts;
        this.testResults = testResults;
    }

    public TestResult execute(UUID candidateId, UUID attemptId) {
        TestAttempt attempt = testAttempts.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Tentative introuvable"));
        if (!attempt.candidateId().equals(candidateId)) {
            throw new ForbiddenException("Cette tentative ne vous appartient pas");
        }
        if (attempt.status() != TestAttemptStatus.IN_PROGRESS) {
            throw new ConflictException("ATTEMPT_ALREADY_SUBMITTED", "Cette tentative a déjà été résolue");
        }

        Instant now = Instant.now();
        TestResult result = TestResult.abandon(attempt.jobOfferId(), attempt.hardSkillTestId(), candidateId,
            attempt.startedAt(), now);
        TestResult saved = testResults.save(result);

        attempt.markResolved(TestAttemptStatus.SUBMITTED);
        testAttempts.save(attempt);
        return saved;
    }
}
