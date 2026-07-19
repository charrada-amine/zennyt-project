package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.RealtimeEventPort;
import com.zennyt.engagement.domain.model.CallSession;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.repository.CallSessionRepository;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.vo.CallType;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class InitiateCallUseCase {
    private final ConversationRepository conversations;
    private final CallSessionRepository calls;
    private final RealtimeEventPort realtime;
    @Transactional public CallSession execute(UUID actorId, UUID conversationId,
                                              CallType type, String offer) {
        Conversation conversation = conversations.findByIdAndParticipantId(conversationId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation introuvable"));
        UUID counterpartId = conversation.counterpartIdFor(actorId);
        CallSession saved = calls.save(CallSession.initiate(
            conversationId, type, actorId, counterpartId, offer));
        realtime.sendToUser(counterpartId, "/queue/call/invite", Map.of(
            "callId", saved.id(), "conversationId", conversationId,
            "initiatorId", actorId, "type", type.name(), "webrtcOffer", offer));
        return saved;
    }
}
