package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.vo.NotificationType;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class NotificationTest {

    @Test
    void create_uses_the_contract_vocabulary() {
        UUID userId = UUID.randomUUID();

        Notification notification = Notification.create(
            userId, NotificationType.NEW_MESSAGE, "New message", "Ada replied",
            "/conversations/123");

        assertNotNull(notification.id());
        assertEquals(userId, notification.userId());
        assertEquals(NotificationType.NEW_MESSAGE, notification.type());
        assertEquals("New message", notification.title());
        assertEquals("Ada replied", notification.body());
        assertEquals("/conversations/123", notification.actionUrl());
        assertFalse(notification.isRead());
        assertNotNull(notification.createdAt());
    }

    @Test
    void mark_as_read_is_idempotent() {
        Notification notification = Notification.create(
            UUID.randomUUID(), NotificationType.APPLICATION_VIEWED, "Viewed", "Application viewed", null);

        notification.markAsRead();
        notification.markAsRead();

        assertTrue(notification.isRead());
    }

    @Test
    void rehydrate_preserves_persisted_state() {
        UUID id = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Instant createdAt = Instant.parse("2026-07-18T08:00:00Z");

        Notification notification = Notification.rehydrate(
            id, userId, NotificationType.JOB_MATCH, "Match", "A job matches your profile",
            "/matches/1", true, createdAt);

        assertEquals(id, notification.id());
        assertEquals("A job matches your profile", notification.body());
        assertTrue(notification.isRead());
        assertEquals(createdAt, notification.createdAt());
    }

    @Test
    void title_and_body_are_required() {
        UUID userId = UUID.randomUUID();

        assertThrows(IllegalArgumentException.class,
            () -> Notification.create(userId, NotificationType.NEW_MESSAGE, " ", "Body", null));
        assertThrows(IllegalArgumentException.class,
            () -> Notification.create(userId, NotificationType.NEW_MESSAGE, "Title", null, null));
    }
}
