package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.MarkAllNotificationsAsReadUseCase;
import com.zennyt.engagement.application.usecase.MarkNotificationAsReadUseCase;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class NotificationUseCasesTest {
    private final NotificationRepository notifications = mock(NotificationRepository.class);

    @Test
    void marks_only_a_notification_owned_by_the_actor() {
        UUID actorId = UUID.randomUUID();
        Notification notification = Notification.create(actorId, NotificationType.JOB_MATCH,
            "Match", "Une offre correspond à votre profil", "/matches/1");
        when(notifications.findByIdAndUserId(notification.id(), actorId))
            .thenReturn(Optional.of(notification));

        new MarkNotificationAsReadUseCase(notifications).execute(actorId, notification.id());

        assertThat(notification.isRead()).isTrue();
        verify(notifications).save(notification);
    }

    @Test
    void does_not_reveal_another_users_notification() {
        UUID actorId = UUID.randomUUID();
        UUID notificationId = UUID.randomUUID();
        when(notifications.findByIdAndUserId(notificationId, actorId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> new MarkNotificationAsReadUseCase(notifications)
            .execute(actorId, notificationId)).isInstanceOf(NotFoundException.class);
        verify(notifications, never()).save(any());
    }

    @Test
    void mark_all_is_scoped_to_the_actor() {
        UUID actorId = UUID.randomUUID();

        new MarkAllNotificationsAsReadUseCase(notifications).execute(actorId);

        verify(notifications).markAllAsRead(actorId);
    }
}
