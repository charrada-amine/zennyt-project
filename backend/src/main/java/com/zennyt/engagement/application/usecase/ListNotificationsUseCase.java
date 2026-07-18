package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ListNotificationsUseCase {
    private final NotificationRepository notifications;

    @Transactional(readOnly = true)
    public Result execute(UUID actorId, boolean unreadOnly, int page, int size) {
        ListConversationsUseCase.validatePage(page, size);
        return new Result(notifications.countUnreadByUserId(actorId),
            notifications.findByUserId(actorId, unreadOnly, page, size));
    }

    public record Result(long unreadCount, PageSlice<Notification> notifications) {}
}
