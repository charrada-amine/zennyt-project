package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.MessageRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MarkConversationAsReadUseCase {
    private final ConversationRepository conversations;
    private final MessageRepository messages;

    @Transactional
    public void execute(UUID actorId, UUID conversationId) {
        Conversation conversation = conversations.findByIdAndParticipantId(conversationId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation introuvable"));
        conversation.markAsReadBy(actorId);
        conversations.save(conversation);
        messages.markReceivedMessagesAsRead(conversationId, actorId, Instant.now());
    }
}
