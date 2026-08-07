package com.zennyt.engagement.application;

import com.zennyt.engagement.application.listener.*;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.engagement.application.port.ProcessedEventStore;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

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

    private MatchCreatedListener matchCreated;

    @BeforeEach
    void setUp() {
        processedEvents = mock(ProcessedEventStore.class);
        applications = mock(EngagementApplicationRepository.class);
        conversations = mock(ConversationRepository.class);
        notifications = mock(NotificationRepository.class);
        retryStore = mock(ApplicationEventRetryStore.class);
        matchCreated = new MatchCreatedListener(
            new MatchCreatedProjector(processedEvents, applications, conversations, notifications),
            retryStore);
    }

    private MatchCreatedEvent matchEvent() {
        return MatchCreatedEvent.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "Backend Engineer");
    }

    @Test
    void first_match_created_event_projects_creates_conversation_and_notifies() {
        when(processedEvents.claim(any())).thenReturn(true);
        when(conversations.createIfAbsent(any())).thenReturn(true);

        matchCreated.on(matchEvent());

        verify(applications).upsert(any());
        verify(conversations).createIfAbsent(any());
        verify(notifications).save(any());
    }

    @Test
    void replayed_match_created_event_is_a_full_no_op() {
        when(processedEvents.claim(any())).thenReturn(false);

        matchCreated.on(matchEvent());

        verify(applications, never()).upsert(any());
        verify(conversations, never()).createIfAbsent(any());
        verify(notifications, never()).save(any());
    }

    @Test
    void failed_projection_is_queued_without_escaping_to_recruitment() {
        MatchCreatedProjector failingProjector = mock(MatchCreatedProjector.class);
        MatchCreatedListener safeListener =
            new MatchCreatedListener(failingProjector, retryStore);
        MatchCreatedEvent event = matchEvent();
        doThrow(new IllegalStateException("database down")).when(failingProjector).project(event);

        safeListener.on(event);

        verify(retryStore).enqueue(event, "database down");
    }
}
