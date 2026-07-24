package com.zennyt.engagement.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.vo.NotificationType;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(UUID id, NotificationType type, String title, String body,
                                   String actionUrl, @JsonProperty("isRead") boolean read,
                                   Instant createdAt) {
    public static NotificationResponse from(Notification notification) {
        return new NotificationResponse(notification.id(), notification.type(), notification.title(),
            notification.body(), notification.actionUrl(), notification.isRead(),
            notification.createdAt());
    }
}
