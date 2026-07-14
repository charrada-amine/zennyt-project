package com.zennyt.recruitment.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/** Émis quand un candidat soumet une tentative d'évaluation. */
public record AssessmentAttemptSubmittedEvent(
    UUID eventId, Instant occurredAt,
    UUID attemptId, UUID candidateId, UUID assessmentId, UUID jobOfferId, int score
) implements DomainEvent {

    public static AssessmentAttemptSubmittedEvent of(UUID attemptId, UUID candidateId,
                                                     UUID assessmentId, UUID jobOfferId, int score) {
        return new AssessmentAttemptSubmittedEvent(UUID.randomUUID(), Instant.now(),
            attemptId, candidateId, assessmentId, jobOfferId, score);
    }

    @Override public String eventType() { return "recruitment.assessment_attempt.submitted"; }
}
