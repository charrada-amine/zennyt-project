package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class HelpMessageRepositoryAdapter implements HelpMessageRepository {
    private final JpaHelpMessageRepository jpa;
    @Override public HelpChat.HelpMessage save(HelpChat.HelpMessage message) {
        return toDomain(jpa.save(new HelpMessageEntity(message.id(), message.helpChatId(),
            message.text(), message.timestamp(), message.fromUser())));
    }
    @Override public List<HelpChat.HelpMessage> findByHelpChatId(UUID helpChatId) {
        return jpa.findByHelpChatIdOrderByTimestampAscIdAsc(helpChatId).stream().map(this::toDomain).toList();
    }
    private HelpChat.HelpMessage toDomain(HelpMessageEntity entity) {
        return new HelpChat.HelpMessage(entity.getId(), entity.getHelpChatId(), entity.getText(),
            entity.getTimestamp(), entity.isFromUser());
    }
}
