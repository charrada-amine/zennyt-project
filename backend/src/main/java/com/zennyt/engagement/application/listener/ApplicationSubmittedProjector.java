package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ProcessedEventStore;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Projection atomique de la soumission dans une transaction Engagement indépendante. */
@Service
@RequiredArgsConstructor
public class ApplicationSubmittedProjector {
    private final ProcessedEventStore processedEvents;
    private final EngagementApplicationRepository applications;
    private final ConversationRepository conversations;
    private final NotificationRepository notifications;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(ApplicationSubmittedEvent event) {
        if (!processedEvents.claim(event.eventId())) return;

        applications.upsert(new EngagementApplication(
            event.applicationId(), event.jobOfferId(), event.candidateId(),
            event.recruiterId(), event.jobTitle(), event.eventId(), event.occurredAt()));
        conversations.createIfAbsent(Conversation.create(event.applicationId(), event.jobOfferId(),
            event.candidateId(), event.recruiterId(), event.jobTitle()));
        notifications.save(Notification.create(event.recruiterId(),
            NotificationType.APPLICATION_STATUS_CHANGED, "Nouvelle candidature",
            "Une candidature a été reçue pour " + event.jobTitle(),
            "/recruitment/applications/" + event.applicationId()));
    }
}
