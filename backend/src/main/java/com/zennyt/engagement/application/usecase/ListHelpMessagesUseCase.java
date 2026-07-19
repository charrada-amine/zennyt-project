package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class ListHelpMessagesUseCase {
    private final HelpChatRepository chats;
    private final HelpMessageRepository messages;
    @Transactional(readOnly = true) public List<HelpChat.HelpMessage> execute(UUID actorId, UUID chatId) {
        chats.findByIdAndUserId(chatId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation d'aide introuvable"));
        return messages.findByHelpChatId(chatId);
    }
}
