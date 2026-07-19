package com.zennyt.engagement.application;

import com.zennyt.engagement.application.listener.ApplicationEventRetryWorker;
import com.zennyt.engagement.application.listener.ApplicationStatusChangedProjector;
import com.zennyt.engagement.application.listener.ApplicationSubmittedProjector;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ApplicationEventRetryWorkerTest {
    private final ApplicationEventRetryStore retryStore = mock(ApplicationEventRetryStore.class);
    private final ApplicationSubmittedProjector submitted = mock(ApplicationSubmittedProjector.class);
    private final ApplicationStatusChangedProjector statusChanged = mock(ApplicationStatusChangedProjector.class);
    private final ApplicationEventRetryWorker worker =
        new ApplicationEventRetryWorker(retryStore, submitted, statusChanged);

    @Test
    void successful_retry_projects_then_deletes_the_pending_event() {
        ApplicationSubmittedEvent event = event();
        when(retryStore.findDue(any(Instant.class), anyInt()))
            .thenReturn(List.of(new ApplicationEventRetryStore.PendingEvent(event, 0)));

        worker.retryDueEvents();

        verify(submitted).project(event);
        verify(retryStore).delete(event.eventId());
        verify(retryStore, never()).reschedule(any(), any(), any());
    }

    @Test
    void failed_retry_is_rescheduled_without_deleting_the_event() {
        ApplicationSubmittedEvent event = event();
        when(retryStore.findDue(any(Instant.class), anyInt()))
            .thenReturn(List.of(new ApplicationEventRetryStore.PendingEvent(event, 2)));
        doThrow(new IllegalStateException("still down")).when(submitted).project(event);

        worker.retryDueEvents();

        verify(retryStore, never()).delete(any());
        verify(retryStore).reschedule(eq(event.eventId()), any(Instant.class), eq("still down"));
    }

    private ApplicationSubmittedEvent event() {
        return ApplicationSubmittedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer");
    }
}
