package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ProcessedEventStore;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.EngagementApplication;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.EngagementApplicationRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Projection atomique du match dans une transaction Engagement indépendante.
 *
 * <p>Remplace {@code ApplicationSubmittedProjector} : l'entité Application
 * n'existe plus côté Recruitment (contrat squad web §5/§6, swipes mutuels
 * RIGHT remplacent le dépôt de candidature) — un match mutuel est désormais
 * le moment où la conversation s'ouvre et le recruteur est notifié.
 */
@Service
@RequiredArgsConstructor
public class MatchCreatedProjector {
    private final ProcessedEventStore processedEvents;
    private final EngagementApplicationRepository applications;
    private final ConversationRepository conversations;
    private final NotificationRepository notifications;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(MatchCreatedEvent event) {
        if (!processedEvents.claim(event.eventId())) return;

        applications.upsert(new EngagementApplication(
            event.matchId(), event.jobOfferId(), event.candidateId(),
            event.recruiterId(), event.jobTitle(), event.eventId(), event.occurredAt()));
        conversations.createIfAbsent(Conversation.create(event.matchId(), event.jobOfferId(),
            event.candidateId(), event.recruiterId(), event.jobTitle()));
        notifications.save(Notification.create(event.recruiterId(),
            NotificationType.JOB_MATCH, "Nouveau match",
            "Vous avez un nouveau match pour " + event.jobTitle(),
            "/recruitment/matches/" + event.matchId()));
    }
}
