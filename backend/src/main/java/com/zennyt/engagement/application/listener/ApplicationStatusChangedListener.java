package com.zennyt.engagement.application.listener;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.recruitment.domain.event.ApplicationStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
public class ApplicationStatusChangedListener {
    private final NotificationRepository notifications;

    @TransactionalEventListener
    public void on(ApplicationStatusChangedEvent event) {
        NotificationType type = event.newStatus().name().equals("SHORTLISTED")
            ? NotificationType.APPLICATION_VIEWED : NotificationType.APPLICATION_STATUS_CHANGED;
        notifications.save(Notification.create(event.candidateId(), type,
            "Candidature mise à jour",
            "Votre candidature pour " + event.jobTitle() + " est maintenant " + event.newStatus().name(),
            "/applications/" + event.applicationId()));
    }
}
