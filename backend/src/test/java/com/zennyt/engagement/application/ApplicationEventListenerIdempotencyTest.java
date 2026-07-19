package com.zennyt.engagement.application;

import com.zennyt.engagement.application.listener.*;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.engagement.application.port.ProcessedEventStore;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/** Prouve l'idempotence : un rejeu d'événement ne duplique ni conversation ni notification. */
class ApplicationEventListenerIdempotencyTest {

    private ProcessedEventStore processedEvents;
    private EngagementApplicationRepository applications;
    private ConversationRepository conversations;
    private NotificationRepository notifications;
    private ApplicationEventRetryStore retryStore;

    private ApplicationSubmittedListener submitted;
    private ApplicationStatusChangedListener statusChanged;

    @BeforeEach
    void setUp() {
        processedEvents = mock(ProcessedEventStore.class);
        applications = mock(EngagementApplicationRepository.class);
        conversations = mock(ConversationRepository.class);
        notifications = mock(NotificationRepository.class);
        retryStore = mock(ApplicationEventRetryStore.class);
        submitted = new ApplicationSubmittedListener(
            new ApplicationSubmittedProjector(processedEvents, applications, conversations, notifications),
            retryStore);
        statusChanged = new ApplicationStatusChangedListener(
            new ApplicationStatusChangedProjector(processedEvents, notifications), retryStore);
    }

    private ApplicationSubmittedEvent submitEvent() {
        return ApplicationSubmittedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer");
    }

    @Test
    void first_submitted_event_projects_creates_conversation_and_notifies() {
        when(processedEvents.claim(any())).thenReturn(true);
        when(conversations.createIfAbsent(any())).thenReturn(true);

        submitted.on(submitEvent());

        verify(applications).upsert(any());
        verify(conversations).createIfAbsent(any());
        verify(notifications).save(any());
    }

    @Test
    void replayed_submitted_event_is_a_full_no_op() {
        when(processedEvents.claim(any())).thenReturn(false);

        submitted.on(submitEvent());

        verify(applications, never()).upsert(any());
        verify(conversations, never()).createIfAbsent(any());
        verify(notifications, never()).save(any());
    }

    @Test
    void replayed_status_changed_event_creates_no_notification() {
        when(processedEvents.claim(any())).thenReturn(false);
        var event = ApplicationStatusChangedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer", ApplicationStatus.PENDING, ApplicationStatus.SHORTLISTED);

        statusChanged.on(event);

        verify(notifications, never()).save(any());
    }

    @Test
    void first_status_changed_event_creates_one_notification() {
        when(processedEvents.claim(any())).thenReturn(true);
        var event = ApplicationStatusChangedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer", ApplicationStatus.PENDING, ApplicationStatus.SHORTLISTED);

        statusChanged.on(event);

        verify(notifications, times(1)).save(any());
    }

    @Test
    void failed_projection_is_queued_without_escaping_to_recruitment() {
        ApplicationSubmittedProjector failingProjector = mock(ApplicationSubmittedProjector.class);
        ApplicationSubmittedListener safeListener =
            new ApplicationSubmittedListener(failingProjector, retryStore);
        ApplicationSubmittedEvent event = submitEvent();
        doThrow(new IllegalStateException("database down")).when(failingProjector).project(event);

        safeListener.on(event);

        verify(retryStore).enqueue(event, "database down");
    }
}
