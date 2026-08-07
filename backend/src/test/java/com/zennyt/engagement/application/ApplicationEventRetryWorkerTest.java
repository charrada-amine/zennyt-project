package com.zennyt.engagement.application;

import com.zennyt.engagement.application.listener.ApplicationEventRetryWorker;
import com.zennyt.engagement.application.listener.MatchCreatedProjector;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ApplicationEventRetryWorkerTest {
    private final ApplicationEventRetryStore retryStore = mock(ApplicationEventRetryStore.class);
    private final MatchCreatedProjector matchCreated = mock(MatchCreatedProjector.class);
    private final ApplicationEventRetryWorker worker =
        new ApplicationEventRetryWorker(retryStore, matchCreated);

    @Test
    void successful_retry_projects_then_deletes_the_pending_event() {
        MatchCreatedEvent event = event();
        when(retryStore.findDue(any(Instant.class), anyInt()))
            .thenReturn(List.of(new ApplicationEventRetryStore.PendingEvent(event, 0)));

        worker.retryDueEvents();

        verify(matchCreated).project(event);
        verify(retryStore).delete(event.eventId());
        verify(retryStore, never()).reschedule(any(), any(), any());
    }

    @Test
    void failed_retry_is_rescheduled_without_deleting_the_event() {
        MatchCreatedEvent event = event();
        when(retryStore.findDue(any(Instant.class), anyInt()))
            .thenReturn(List.of(new ApplicationEventRetryStore.PendingEvent(event, 2)));
        doThrow(new IllegalStateException("still down")).when(matchCreated).project(event);

        worker.retryDueEvents();

        verify(retryStore, never()).delete(any());
        verify(retryStore).reschedule(eq(event.eventId()), any(Instant.class), eq("still down"));
    }

    private MatchCreatedEvent event() {
        return MatchCreatedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer");
    }
}
