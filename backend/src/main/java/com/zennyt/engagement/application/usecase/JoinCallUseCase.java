package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.RealtimeEventPort;
import com.zennyt.engagement.domain.model.CallSession;
import com.zennyt.engagement.domain.repository.CallSessionRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class JoinCallUseCase {
    private final CallSessionRepository calls;
    private final RealtimeEventPort realtime;
    @Transactional public CallSession execute(UUID actorId, UUID callId, String answer) {
        CallSession call = calls.findById(callId)
            .filter(value -> value.isParticipant(actorId))
            .orElseThrow(() -> new NotFoundException("Appel introuvable"));
        call.join(actorId, answer);
        CallSession saved = calls.save(call);
        realtime.sendToUser(call.initiatorId(), "/queue/call/accept", Map.of(
            "callId", callId, "webrtcAnswer", answer));
        return saved;
    }
}
