package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.model.PageSlice;

import java.util.Optional;
import java.util.UUID;

public interface NotificationRepository {
    Notification save(Notification notification);
    Optional<Notification> findByIdAndUserId(UUID id, UUID userId);
    PageSlice<Notification> findByUserId(UUID userId, boolean unreadOnly, int page, int size);
    long countUnreadByUserId(UUID userId);
    void markAllAsRead(UUID userId);
}
