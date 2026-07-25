package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/**
 * Émis quand un candidat termine un test de compétences avec un score réel
 * (COMPLETED ou TIMEOUT — jamais ABANDONED, qui n'a rien de significatif à
 * résumer). Remplace {@code AssessmentAttemptSubmittedEvent}.
 */
public record TestResultCompletedEvent(
    UUID eventId, Instant occurredAt,
    UUID testResultId, UUID candidateId, UUID hardSkillTestId, UUID jobOfferId, int percentage, boolean passed
) implements DomainEvent {

    public static TestResultCompletedEvent of(UUID testResultId, UUID candidateId, UUID hardSkillTestId,
                                              UUID jobOfferId, int percentage, boolean passed) {
        return new TestResultCompletedEvent(UUID.randomUUID(), Instant.now(),
            testResultId, candidateId, hardSkillTestId, jobOfferId, percentage, passed);
    }

    @Override public String eventType() { return "recruitment.test_result.completed"; }
}
