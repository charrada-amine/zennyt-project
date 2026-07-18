package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.recruitment.domain.event.ApplicationSubmittedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/** Builds Engagement state from the public Recruitment event, without direct module calls. */
@Component
@RequiredArgsConstructor
public class ApplicationSubmittedListener {
    private final ConversationRepository conversations;
    private final NotificationRepository notifications;

    @TransactionalEventListener
    public void on(ApplicationSubmittedEvent event) {
        if (conversations.findByApplicationIdAndParticipantId(event.applicationId(), event.candidateId()).isEmpty()) {
            conversations.save(Conversation.create(event.applicationId(), event.jobOfferId(),
                event.candidateId(), event.recruiterId(), event.jobTitle()));
        }
        notifications.save(Notification.create(event.recruiterId(), NotificationType.APPLICATION_STATUS_CHANGED,
            "Nouvelle candidature", "Une candidature a été reçue pour " + event.jobTitle(),
            "/recruitment/applications/" + event.applicationId()));
    }
}
