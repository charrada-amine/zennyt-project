package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.usecase.ListNotificationsUseCase;

import java.util.List;

public record NotificationPageResponse(long unreadCount, List<NotificationResponse> content,
                                       PageMetaResponse page) {
    public static NotificationPageResponse from(ListNotificationsUseCase.Result result) {
        var slice = result.notifications();
        return new NotificationPageResponse(result.unreadCount(),
            slice.content().stream().map(NotificationResponse::from).toList(),
            PageMetaResponse.from(slice));
    }
}
