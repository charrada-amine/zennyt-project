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
    private final List<Integer> answers;
    private int score;
    private boolean passed;
    private IntegrityStatus integrityStatus;
    private final Instant submittedAt;

    private AssessmentAttempt(UUID id, UUID assessmentId, UUID candidateId, UUID jobOfferId,
                              List<Integer> answers) {
        this.id = id;
        this.assessmentId = assessmentId;
        this.candidateId = candidateId;
        this.jobOfferId = jobOfferId;
        this.answers = List.copyOf(answers);
        this.integrityStatus = IntegrityStatus.PENDING;
        this.submittedAt = Instant.now();
    }

    /** Fabrique : soumettre une tentative, calculer le score, émettre l'événement. */
    public static AssessmentAttempt submit(UUID candidateId, UUID assessmentId, UUID jobOfferId,
                                           List<Integer> answers, List<AssessmentQuestion> questions) {
        AssessmentAttempt attempt = new AssessmentAttempt(UUID.randomUUID(), assessmentId,
            candidateId, jobOfferId, answers);

        // Calcul du score
        int correct = 0;
        for (int i = 0; i < Math.min(answers.size(), questions.size()); i++) {
            if (answers.get(i) == questions.get(i).correctOptionIndex()) {
                correct++;
            }
        }
        attempt.score = questions.isEmpty() ? 0 : (correct * 100) / questions.size();
        attempt.passed = attempt.score >= 50; // seuil de réussite à 50%

        attempt.registerEvent(AssessmentAttemptSubmittedEvent.of(
            attempt.id, candidateId, assessmentId, jobOfferId, attempt.score));
        return attempt;
    }

    /** Reconstruction depuis la persistance. */
    public static AssessmentAttempt rehydrate(UUID id, UUID assessmentId, UUID candidateId,
                                              UUID jobOfferId, int score, boolean passed,
                                              IntegrityStatus integrityStatus, Instant submittedAt) {
        AssessmentAttempt attempt = new AssessmentAttempt(id, assessmentId, candidateId,
            jobOfferId, List.of());
        attempt.score = score;
        attempt.passed = passed;
        attempt.integrityStatus = integrityStatus;
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
    public int score() { return score; }
    public boolean passed() { return passed; }
    public IntegrityStatus integrityStatus() { return integrityStatus; }
    public Instant submittedAt() { return submittedAt; }
}
