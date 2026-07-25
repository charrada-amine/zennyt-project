package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.TestAttemptStatus;
import com.zennyt.shared.domain.model.AggregateRoot;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * Agrégat TestAttempt — ressource technique/interne qui porte le mécanisme de
 * mélange (contrat squad web §7.1). Minimalement exposée : {@code
 * presentedQuestions} n'est jamais sérialisé dans une réponse API.
 *
 * <p>Questions et options sont mélangées une fois, à la création, et le
 * mapping est conservé pour noter la soumission quel que soit l'ordre de
 * présentation.
 */
public class TestAttempt extends AggregateRoot {

    private final UUID id;
    private final UUID jobOfferId;
    private final UUID hardSkillTestId;
    private final UUID candidateId;
    private final Instant startedAt;
    private final Instant expiresAt;
    private final List<PresentedQuestion> presentedQuestions;
    private TestAttemptStatus status;

    private TestAttempt(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                        Instant startedAt, Instant expiresAt,
                        List<PresentedQuestion> presentedQuestions, TestAttemptStatus status) {
        this.id = id;
        this.jobOfferId = jobOfferId;
        this.hardSkillTestId = hardSkillTestId;
        this.candidateId = candidateId;
        this.startedAt = startedAt;
        this.expiresAt = expiresAt;
        this.presentedQuestions = List.copyOf(presentedQuestions);
        this.status = status;
    }

    /** Fabrique : démarre une tentative, mélange l'ordre des questions et de leurs options. */
    public static TestAttempt start(UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                                    List<AssessmentQuestion> questions, int timeLimitSeconds) {
        List<AssessmentQuestion> shuffledQuestions = new ArrayList<>(questions);
        Collections.shuffle(shuffledQuestions);
        List<PresentedQuestion> mapping = new ArrayList<>();
        for (int i = 0; i < shuffledQuestions.size(); i++) {
            AssessmentQuestion q = shuffledQuestions.get(i);
            List<Integer> optionOrder = new ArrayList<>();
            for (int j = 0; j < q.options().size(); j++) optionOrder.add(j);
            Collections.shuffle(optionOrder);
            mapping.add(new PresentedQuestion(q.id(), i + 1, optionOrder));
        }
        Instant now = Instant.now();
        return new TestAttempt(UUID.randomUUID(), jobOfferId, hardSkillTestId, candidateId,
            now, now.plusSeconds(timeLimitSeconds), mapping, TestAttemptStatus.IN_PROGRESS);
    }

    /** Reconstruction depuis la persistance. */
    public static TestAttempt rehydrate(UUID id, UUID jobOfferId, UUID hardSkillTestId, UUID candidateId,
                                        Instant startedAt, Instant expiresAt,
                                        List<PresentedQuestion> presentedQuestions, TestAttemptStatus status) {
        return new TestAttempt(id, jobOfferId, hardSkillTestId, candidateId, startedAt, expiresAt,
            presentedQuestions, status);
    }

    /** Résout la tentative (soumission ou expiration) — un seul appel autorisé. */
    public void markResolved(TestAttemptStatus resolution) {
        if (this.status != TestAttemptStatus.IN_PROGRESS) {
            throw new IllegalStateException("Cette tentative a déjà été résolue");
        }
        this.status = resolution;
    }

    public boolean isExpired(Instant now) {
        return now.isAfter(expiresAt);
    }

    /**
     * Retrouve l'index d'option original pour une question, à partir de
     * l'index affiché (mélangé) soumis par le candidat.
     *
     * @throws IllegalArgumentException si la question n'appartient pas à
     *         cette tentative, ou si l'index est hors limites — 400 (contrat
     *         squad web §7.4)
     */
    public int originalOptionIndex(UUID questionId, int selectedOptionIndex) {
        PresentedQuestion presented = presentedQuestions.stream()
            .filter(p -> p.questionId().equals(questionId))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException(
                "Cette question n'appartient pas à cette tentative : " + questionId));
        if (selectedOptionIndex < 0 || selectedOptionIndex >= presented.optionOrder().size()) {
            throw new IllegalArgumentException(
                "Index de réponse hors limites pour la question " + questionId);
        }
        return presented.optionOrder().get(selectedOptionIndex);
    }

    public UUID id() { return id; }
    public UUID jobOfferId() { return jobOfferId; }
    public UUID hardSkillTestId() { return hardSkillTestId; }
    public UUID candidateId() { return candidateId; }
    public Instant startedAt() { return startedAt; }
    public Instant expiresAt() { return expiresAt; }
    public List<PresentedQuestion> presentedQuestions() { return presentedQuestions; }
    public TestAttemptStatus status() { return status; }
}
