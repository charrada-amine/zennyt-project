package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MarkAllNotificationsAsReadUseCase {
    private final NotificationRepository notifications;

    @Transactional
    public void execute(UUID actorId) {
        notifications.markAllAsRead(actorId);
    }
}
