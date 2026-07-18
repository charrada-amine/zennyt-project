package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class ListHelpChatsUseCase {
    private final HelpChatRepository chats;
    @Transactional public List<HelpChat> execute(UUID actorId) {
        List<HelpChat> existing = chats.findByUserId(actorId);
        if (!existing.isEmpty()) return existing;
        return List.of(chats.save(HelpChat.create(actorId,
            "Support Zennyt", "Comment pouvons-nous vous aider ?")));
    }
}
