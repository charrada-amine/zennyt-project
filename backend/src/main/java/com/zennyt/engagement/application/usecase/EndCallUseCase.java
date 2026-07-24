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
public class EndCallUseCase {
    private final CallSessionRepository calls;
    private final RealtimeEventPort realtime;
    @Transactional public void execute(UUID actorId, UUID callId) {
        CallSession call = calls.findById(callId)
            .filter(value -> value.isParticipant(actorId))
            .orElseThrow(() -> new NotFoundException("Appel introuvable"));
        call.end(actorId);
        calls.save(call);
        UUID counterpart = call.initiatorId().equals(actorId) ? call.counterpartId() : call.initiatorId();
        realtime.sendToUser(counterpart, "/queue/call/end", Map.of("callId", callId));
    }
}
