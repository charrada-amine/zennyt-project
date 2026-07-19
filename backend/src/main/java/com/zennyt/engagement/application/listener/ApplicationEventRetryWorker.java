package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.shared.domain.event.DomainEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

/** Rejoue les projections Recruitment échouées sans bloquer la transaction émettrice. */
@Component
@RequiredArgsConstructor
@Slf4j
public class ApplicationEventRetryWorker {
    private static final long POLL_DELAY_MILLIS = 30_000L;
    private static final int BATCH_SIZE = 25;
    private static final long BASE_RETRY_SECONDS = 30L;
    private static final long MAX_RETRY_SECONDS = 3_600L;

    private final ApplicationEventRetryStore retryStore;
    private final ApplicationSubmittedProjector submittedProjector;
    private final ApplicationStatusChangedProjector statusProjector;

    @Scheduled(fixedDelay = POLL_DELAY_MILLIS, initialDelay = POLL_DELAY_MILLIS)
    public void retryDueEvents() {
        for (ApplicationEventRetryStore.PendingEvent pending
                : retryStore.findDue(Instant.now(), BATCH_SIZE)) {
            try {
                project(pending.event());
                retryStore.delete(pending.event().eventId());
            } catch (RuntimeException failure) {
                Instant nextAttempt = Instant.now().plus(retryDelay(pending.attempts() + 1));
                retryStore.reschedule(pending.event().eventId(), nextAttempt, failure.getMessage());
                log.warn("Retry Engagement échoué pour l'événement {}, prochain essai à {}",
                    pending.event().eventId(), nextAttempt, failure);
            }
        }
    }

    private void project(DomainEvent event) {
        if (event instanceof ApplicationSubmittedEvent submitted) {
            submittedProjector.project(submitted);
        } else if (event instanceof ApplicationStatusChangedEvent statusChanged) {
            statusProjector.project(statusChanged);
        } else {
            throw new IllegalArgumentException("Événement Engagement non supporté: " + event.eventType());
        }
    }

    private Duration retryDelay(int attempts) {
        int boundedExponent = Math.min(Math.max(attempts - 1, 0), 10);
        long seconds = Math.min(BASE_RETRY_SECONDS << boundedExponent, MAX_RETRY_SECONDS);
        return Duration.ofSeconds(seconds);
    }
}
