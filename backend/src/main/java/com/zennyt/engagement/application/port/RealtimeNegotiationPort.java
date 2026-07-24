package com.zennyt.engagement.application.port;

import java.util.UUID;

public interface RealtimeNegotiationPort {
    Connection negotiate(UUID actorId);

    record Connection(String url, String accessToken) {}
}
