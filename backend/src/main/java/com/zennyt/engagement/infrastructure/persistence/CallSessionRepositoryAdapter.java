package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.CallSession;
import com.zennyt.engagement.domain.repository.CallSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class CallSessionRepositoryAdapter implements CallSessionRepository {
    private final JpaCallSessionRepository jpa;
    @Override public CallSession save(CallSession call) {
        CallSessionEntity entity = jpa.findById(call.id()).orElseGet(() -> new CallSessionEntity(
            call.id(), call.conversationId(), call.type(), call.status(), call.initiatorId(),
            call.counterpartId(), call.webrtcOffer(), call.webrtcAnswer(), call.startedAt(),
            call.endedAt(), call.durationSeconds()));
        entity.update(call.status(), call.webrtcAnswer(), call.endedAt(), call.durationSeconds());
        return toDomain(jpa.save(entity));
    }
    @Override public Optional<CallSession> findById(UUID callId) { return jpa.findById(callId).map(this::toDomain); }
    private CallSession toDomain(CallSessionEntity entity) {
        return CallSession.rehydrate(entity.getId(), entity.getConversationId(), entity.getType(),
            entity.getStatus(), entity.getInitiatorId(), entity.getCounterpartId(),
            entity.getWebrtcOffer(), entity.getWebrtcAnswer(), entity.getStartedAt(),
            entity.getEndedAt(), entity.getDurationSeconds());
    }
}
