package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class SendHelpMessageUseCase {
    private final HelpChatRepository chats;
    private final HelpMessageRepository messages;
    @Transactional public HelpChat.HelpMessage execute(UUID actorId, UUID chatId, String text) {
        HelpChat chat = chats.findByIdAndUserId(chatId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation d'aide introuvable"));
        HelpChat.HelpMessage message = chat.recordMessage(text, true);
        chats.save(chat);
        return messages.save(message);
    }
}
