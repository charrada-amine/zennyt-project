package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CreateConversationUseCase {
    private final ConversationRepository conversations;

    @Transactional(readOnly = true)
    public Conversation execute(UUID actorId, UUID applicationId) {
        return conversations.findByApplicationIdAndParticipantId(applicationId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation de candidature introuvable"));
    }
}
