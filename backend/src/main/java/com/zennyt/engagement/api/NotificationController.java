package com.zennyt.engagement.api;

import com.zennyt.engagement.api.dto.NotificationPageResponse;
import com.zennyt.engagement.api.security.EngagementAuthenticated;
import com.zennyt.engagement.application.usecase.ListNotificationsUseCase;
import com.zennyt.engagement.application.usecase.MarkAllNotificationsAsReadUseCase;
import com.zennyt.engagement.application.usecase.MarkNotificationAsReadUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final ListNotificationsUseCase listNotifications;
    private final MarkNotificationAsReadUseCase markNotificationAsRead;
    private final MarkAllNotificationsAsReadUseCase markAllAsRead;

    @GetMapping
    @EngagementAuthenticated
    public ResponseEntity<NotificationPageResponse> list(
            @RequestParam(defaultValue = "false") boolean unreadOnly,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        return ResponseEntity.ok(NotificationPageResponse.from(
            listNotifications.execute(actor(principal), unreadOnly, page, size)));
    }

    @PostMapping("/{notificationId}/read")
    @EngagementAuthenticated
    public ResponseEntity<Void> read(@PathVariable UUID notificationId, Principal principal) {
        markNotificationAsRead.execute(actor(principal), notificationId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/read-all")
    @EngagementAuthenticated
    public ResponseEntity<Void> readAll(Principal principal) {
        markAllAsRead.execute(actor(principal));
        return ResponseEntity.noContent().build();
    }

    private static UUID actor(Principal principal) {
        return UUID.fromString(principal.getName());
    }
}
