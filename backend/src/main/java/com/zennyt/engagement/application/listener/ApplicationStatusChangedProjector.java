package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.application.port.ProcessedEventStore;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Projection atomique d'un changement de statut dans une transaction indépendante. */
@Service
@RequiredArgsConstructor
public class ApplicationStatusChangedProjector {
    private final ProcessedEventStore processedEvents;
    private final NotificationRepository notifications;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void project(ApplicationStatusChangedEvent event) {
        if (!processedEvents.claim(event.eventId())) return;

        NotificationType type = event.newStatus().name().equals("SHORTLISTED")
            ? NotificationType.APPLICATION_VIEWED : NotificationType.APPLICATION_STATUS_CHANGED;
        notifications.save(Notification.create(event.candidateId(), type,
            "Candidature mise à jour",
            "Votre candidature pour " + event.jobTitle() + " est maintenant " + event.newStatus().name(),
            "/applications/" + event.applicationId()));
    }
}
