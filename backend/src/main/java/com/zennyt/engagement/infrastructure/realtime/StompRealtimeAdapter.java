package com.zennyt.engagement.infrastructure.realtime;

import com.zennyt.engagement.application.port.RealtimeEventPort;
import com.zennyt.engagement.application.port.RealtimeNegotiationPort;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class StompRealtimeAdapter implements RealtimeEventPort, RealtimeNegotiationPort {
    private final SimpMessagingTemplate messaging;

    @Value("${engagement.realtime.url:/ws-engagement}")
    private String url;

    @Override
    public void sendToUser(UUID userId, String destination, Map<String, Object> payload) {
        messaging.convertAndSendToUser(userId.toString(), destination, payload);
    }

    @Override
    public Connection negotiate(UUID actorId) {
        // The authenticated HTTP upgrade reuses the caller's bearer token.
        return new Connection(url, null);
    }
}
