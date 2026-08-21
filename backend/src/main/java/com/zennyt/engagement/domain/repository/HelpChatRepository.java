package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.HelpChat;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HelpChatRepository {
    HelpChat save(HelpChat chat);
    List<HelpChat> findByUserId(UUID userId);
    Optional<HelpChat> findByIdAndUserId(UUID helpChatId, UUID userId);

    /**
     * Recherche sans filtre d'utilisateur, réservée à l'assistant : il répond dans une
     * conversation dont l'appartenance a déjà été vérifiée au moment de l'envoi du message.
     * Toute lecture déclenchée par une requête utilisateur passe par
     * {@link #findByIdAndUserId}.
     */
    Optional<HelpChat> findById(UUID helpChatId);
}
