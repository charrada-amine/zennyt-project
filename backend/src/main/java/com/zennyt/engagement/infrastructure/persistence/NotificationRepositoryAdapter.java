package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class NotificationRepositoryAdapter implements NotificationRepository {
    private final JpaNotificationRepository jpa;

    @Override
    public Notification save(Notification notification) {
        return toDomain(jpa.save(new NotificationEntity(
            notification.id(), notification.userId(), notification.type(), notification.title(),
            notification.body(), notification.actionUrl(), notification.isRead(),
            notification.createdAt())));
    }

    @Override
    public Optional<Notification> findByIdAndUserId(UUID id, UUID userId) {
        return jpa.findByIdAndUserId(id, userId).map(this::toDomain);
    }

    @Override
    public PageSlice<Notification> findByUserId(
            UUID userId, boolean unreadOnly, int page, int size) {
        var pageable = PageRequest.of(page, size,
            Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id")));
        var result = unreadOnly
            ? jpa.findByUserIdAndReadFalse(userId, pageable)
            : jpa.findByUserId(userId, pageable);
        return new PageSlice<>(result.map(this::toDomain).getContent(),
            result.getNumber(), result.getSize(), result.getTotalElements());
    }

    @Override
    public long countUnreadByUserId(UUID userId) {
        return jpa.countByUserIdAndReadFalse(userId);
    }

    @Override
    public void markAllAsRead(UUID userId) {
        jpa.markAllAsRead(userId);
    }

    private Notification toDomain(NotificationEntity entity) {
        return Notification.rehydrate(entity.getId(), entity.getUserId(), entity.getType(),
            entity.getTitle(), entity.getBody(), entity.getActionUrl(), entity.isRead(),
            entity.getCreatedAt());
    }
}
