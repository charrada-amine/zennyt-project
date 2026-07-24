package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.MessageRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ListMessagesUseCase {
    private final ConversationRepository conversations;
    private final MessageRepository messages;

    @Transactional(readOnly = true)
    public List<Conversation.Message> execute(
            UUID actorId, UUID conversationId, UUID beforeMessageId, int size) {
        ListConversationsUseCase.validatePage(0, size);
        conversations.findByIdAndParticipantId(conversationId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation introuvable"));
        return messages.findRecent(conversationId, beforeMessageId, size);
    }
}
