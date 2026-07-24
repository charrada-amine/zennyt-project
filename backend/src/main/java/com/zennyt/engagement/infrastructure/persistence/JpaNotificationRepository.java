package com.zennyt.engagement.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

interface JpaNotificationRepository extends JpaRepository<NotificationEntity, UUID> {
    Optional<NotificationEntity> findByIdAndUserId(UUID id, UUID userId);
    Page<NotificationEntity> findByUserId(UUID userId, Pageable pageable);
    Page<NotificationEntity> findByUserIdAndReadFalse(UUID userId, Pageable pageable);
    long countByUserIdAndReadFalse(UUID userId);

    @Modifying
    @Query("update NotificationEntity notification set notification.read = true " +
           "where notification.userId = :userId and notification.read = false")
    int markAllAsRead(@Param("userId") UUID userId);
}
