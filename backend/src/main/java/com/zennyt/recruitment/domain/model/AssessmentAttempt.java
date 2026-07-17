package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.AssessmentAttemptSubmittedEvent;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Agrégat Tentative d'évaluation — réponses d'un candidat à un test.
 *
 * <p>Une seule tentative autorisée par (candidateId, assessmentId, jobOfferId).
 * Après soumission, le statut d'intégrité est PENDING jusqu'au callback anti-fraude.
 */
public class AssessmentAttempt extends AggregateRoot {

    private final UUID id;
    private final UUID assessmentId;
    private final UUID candidateId;
    private final UUID jobOfferId;
    private final UUID applicationId;
    private final List<Integer> answers;
    private int score;
    private boolean passed;
    private IntegrityStatus integrityStatus;
    private Instant submittedAt;

    private AssessmentAttempt(UUID id, UUID assessmentId, UUID candidateId, UUID jobOfferId,
                              UUID applicationId, List<Integer> answers) {
        this.id = id;
        this.assessmentId = assessmentId;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.applicationId = applicationId;
        this.answers = List.copyOf(answers);
        this.integrityStatus = IntegrityStatus.PENDING;
        this.submittedAt = Instant.now();
    }

    /** Fabrique : soumettre une tentative, calculer le score, émettre l'événement. */
    public static AssessmentAttempt submit(UUID candidateId, UUID assessmentId, UUID jobOfferId,
                                           UUID applicationId, List<Integer> answers,
                                           List<AssessmentQuestion> questions, int passingScore) {
        if (passingScore < 0 || passingScore > 100) {
            throw new IllegalArgumentException("Le seuil de réussite doit être entre 0 et 100");
        }
        AssessmentAttempt attempt = new AssessmentAttempt(UUID.randomUUID(), assessmentId,
            candidateId, jobOfferId, applicationId, answers);

        // Calcul du score
        int correct = 0;
        for (int i = 0; i < Math.min(answers.size(), questions.size()); i++) {
            if (answers.get(i) == questions.get(i).correctOptionIndex()) {
                correct++;
            }
        }
        attempt.score = questions.isEmpty() ? 0 : (correct * 100) / questions.size();
        attempt.passed = attempt.score >= passingScore;

        attempt.registerEvent(AssessmentAttemptSubmittedEvent.of(
            attempt.id, candidateId, assessmentId, jobOfferId, attempt.score));
        return attempt;
    }

    /** Reconstruction depuis la persistance. */
    public static AssessmentAttempt rehydrate(UUID id, UUID assessmentId, UUID candidateId,
                                              UUID jobOfferId, UUID applicationId,
                                              int score, boolean passed,
                                              IntegrityStatus integrityStatus, Instant submittedAt) {
        AssessmentAttempt attempt = new AssessmentAttempt(id, assessmentId, candidateId,
            jobOfferId, applicationId, List.of());
        attempt.score = score;
        attempt.passed = passed;
        attempt.integrityStatus = integrityStatus;
        attempt.submittedAt = submittedAt;
        return attempt;
    }

    /** Mise à jour du statut d'intégrité par le callback anti-fraude. */
    public void resolveIntegrity(IntegrityStatus result) {
        if (this.integrityStatus != IntegrityStatus.PENDING) {
            throw new IllegalStateException("L'intégrité a déjà été résolue");
        }
        this.integrityStatus = result;
    }

    public UUID id() { return id; }
    public UUID assessmentId() { return assessmentId; }
    public UUID candidateId() { return candidateId; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID applicationId() { return applicationId; }
    public int score() { return score; }
    public boolean passed() { return passed; }
    public IntegrityStatus integrityStatus() { return integrityStatus; }
    public Instant submittedAt() { return submittedAt; }
}
