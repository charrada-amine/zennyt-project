package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.HelpChat;

import java.util.List;
import java.util.UUID;

public interface HelpMessageRepository {
    HelpChat.HelpMessage save(HelpChat.HelpMessage message);
    List<HelpChat.HelpMessage> findByHelpChatId(UUID helpChatId);
}
