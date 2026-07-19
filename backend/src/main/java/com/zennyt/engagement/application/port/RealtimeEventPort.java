package com.zennyt.engagement.application.port;

import java.util.Map;
import java.util.UUID;

public interface RealtimeEventPort {
    void sendToUser(UUID userId, String destination, Map<String, Object> payload);
}
