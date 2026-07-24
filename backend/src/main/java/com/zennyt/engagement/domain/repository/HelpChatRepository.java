package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.HelpChat;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HelpChatRepository {
    HelpChat save(HelpChat chat);
    List<HelpChat> findByUserId(UUID userId);
    Optional<HelpChat> findByIdAndUserId(UUID helpChatId, UUID userId);
}
