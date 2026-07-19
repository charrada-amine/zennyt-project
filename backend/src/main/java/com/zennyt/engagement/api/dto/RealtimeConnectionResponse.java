package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.application.port.RealtimeNegotiationPort;

public record RealtimeConnectionResponse(String url, String accessToken) {
    public static RealtimeConnectionResponse from(RealtimeNegotiationPort.Connection connection) {
        return new RealtimeConnectionResponse(connection.url(), connection.accessToken());
    }
}
