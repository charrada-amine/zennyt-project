package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.vo.TestResultStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Agrégat TestResult — résultat final d'une tentative de test de compétences
 * (contrat squad web §7.1). Un seul résultat par (jobOfferId, candidateId),
 * jamais — l'unicité est appliquée au niveau base (contrainte unique), pas
 * seulement en logique applicative.
 *
 * <p>Seuil de réussite : constante globale fixe à 70%, appliquée uniformément
 * (pas de réglage par offre, contrairement à l'ancien {@code passingScore}).
 */
public class TestResult extends AggregateRoot {

    public static final int PASS_THRESHOLD = 70;

    private final UUID id;
    private final UUID jobOfferId;
    private final UUID hardSkillTestId;
    private final UUID candidateId;
    private final int score;
    private final int percentage;
    private final boolean passed;
    private final List<TestAnswer> answers;
    private final Instant startedAt;
    private final Instant completedAt;
    private final int duration;
    private final TestResultStatus status;

    private TestResult(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                       int score, int percentage, boolean passed, List<TestAnswer> answers,
                       Instant startedAt, Instant completedAt, int duration, TestResultStatus status) {
        this.id = id;
        this.jobOfferId = jobOfferId;
        this.hardSkillTestId = hardSkillTestId;
        this.candidateId = candidateId;
        this.score = score;
        this.percentage = percentage;
        this.passed = passed;
        this.answers = List.copyOf(answers);
        this.startedAt = startedAt;
        this.completedAt = completedAt;
        this.duration = duration;
        this.status = status;
    }

    /**
     * Fabrique : soumission notée (COMPLETED ou TIMEOUT — jamais ABANDONED
     * ici). {@code totalQuestions} sert de dénominateur, pas le nombre de
     * réponses soumises : une question non répondue compte comme incorrecte.
     */
    public static TestResult complete(UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                                      List<TestAnswer> answers, int totalQuestions,
                                      Instant startedAt, Instant completedAt, TestResultStatus status) {
        int score = (int) answers.stream().filter(TestAnswer::correct).count();
        int percentage = totalQuestions == 0 ? 0 : (score * 100) / totalQuestions;
        boolean passed = percentage >= PASS_THRESHOLD;
        int duration = (int) Duration.between(startedAt, completedAt).getSeconds();
        TestResult result = new TestResult(UUID.randomUUID(), jobOfferId, hardSkillTestId, candidateId,
            score, percentage, passed, answers, startedAt, completedAt, duration, status);
        result.registerEvent(TestResultCompletedEvent.of(
            result.id, candidateId, hardSkillTestId, jobOfferId, percentage, passed));
        return result;
    }

    /** Fabrique : abandon explicite — score 0, non réussi, aucun événement de résumé IA. */
    public static TestResult abandon(UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                                     Instant startedAt, Instant completedAt) {
        int duration = (int) Duration.between(startedAt, completedAt).getSeconds();
        return new TestResult(UUID.randomUUID(), jobOfferId, hardSkillTestId, candidateId,
            0, 0, false, List.of(), startedAt, completedAt, duration, TestResultStatus.ABANDONED);
    }

    /** Reconstruction depuis la persistance. */
    public static TestResult rehydrate(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                                       int score, int percentage, boolean passed, List<TestAnswer> answers,
                                       Instant startedAt, Instant completedAt, int duration,
                                       TestResultStatus status) {
        return new TestResult(id, jobOfferId, hardSkillTestId, candidateId, score, percentage, passed,
            answers, startedAt, completedAt, duration, status);
    }

    public UUID id() { return id; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID hardSkillTestId() { return hardSkillTestId; }
    public UUID candidateId() { return candidateId; }
    public int score() { return score; }
    public int percentage() { return percentage; }
    public boolean passed() { return passed; }
    public List<TestAnswer> answers() { return answers; }
    public Instant startedAt() { return startedAt; }
    public Instant completedAt() { return completedAt; }
    public int duration() { return duration; }
    public TestResultStatus status() { return status; }
}
