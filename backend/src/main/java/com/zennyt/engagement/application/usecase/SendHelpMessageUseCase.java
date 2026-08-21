package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.event.HelpQuestionAskedEvent;
import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class SendHelpMessageUseCase {
    private final HelpChatRepository chats;
    private final HelpMessageRepository messages;
    private final ApplicationEventPublisher evenements;
    @Transactional public HelpChat.HelpMessage execute(UUID actorId, UUID chatId, String text) {
        HelpChat chat = chats.findByIdAndUserId(chatId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation d'aide introuvable"));
        HelpChat.HelpMessage message = chat.recordMessage(text, true);
        chats.save(chat);
        HelpChat.HelpMessage enregistre = messages.save(message);

        // La reponse de l'assistant se prepare apres validation, hors de cette requete :
        // faire attendre l'envoi pendant une generation de texte donnerait a l'utilisateur
        // l'impression que son message n'est pas parti.
        evenements.publishEvent(new HelpQuestionAskedEvent(chatId, actorId, text));
        return enregistre;
    }
}
