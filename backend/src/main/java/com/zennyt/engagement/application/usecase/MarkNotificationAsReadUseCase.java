package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MarkNotificationAsReadUseCase {
    private final NotificationRepository notifications;

    @Transactional
    public void execute(UUID actorId, UUID notificationId) {
        Notification notification = notifications.findByIdAndUserId(notificationId, actorId)
            .orElseThrow(() -> new NotFoundException("Notification introuvable"));
        notification.markAsRead();
        notifications.save(notification);
    }
}
