package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import com.zennyt.engagement.domain.vo.HelpChatRating;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Enregistre l'appréciation de l'utilisateur sur une conversation d'aide.
 *
 * <p>La recherche passe par {@code findByIdAndUserId} : on ne note que sa propre
 * conversation. Sans ce filtre, connaître un identifiant suffirait à noter — et à
 * commenter — l'échange de quelqu'un d'autre.
 */
@Service
@RequiredArgsConstructor
public class RateHelpChatUseCase {
    private final HelpChatRepository chats;

    @Transactional
    public HelpChat execute(UUID actorId, UUID chatId, HelpChatRating rating, String comment) {
        HelpChat chat = chats.findByIdAndUserId(chatId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation d'aide introuvable"));
        chat.rate(rating, comment);
        return chats.save(chat);
    }
}
