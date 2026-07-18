package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.CallSession;

import java.util.Optional;
import java.util.UUID;

public interface CallSessionRepository {
    CallSession save(CallSession session);
    Optional<CallSession> findById(UUID callId);
}
