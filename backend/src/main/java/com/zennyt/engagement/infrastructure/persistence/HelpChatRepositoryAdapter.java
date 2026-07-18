package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.repository.HelpChatRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class HelpChatRepositoryAdapter implements HelpChatRepository {
    private final JpaHelpChatRepository jpa;
    @Override public HelpChat save(HelpChat chat) {
        HelpChatEntity entity = jpa.findById(chat.id()).orElseGet(() -> new HelpChatEntity(
            chat.id(), chat.userId(), chat.title(), chat.subtitle(), chat.lastMessageAt()));
        entity.update(chat.lastMessageAt());
        return toDomain(jpa.save(entity));
    }
    @Override public List<HelpChat> findByUserId(UUID userId) {
        return jpa.findByUserIdOrderByLastMessageAtDesc(userId).stream().map(this::toDomain).toList();
    }
    @Override public Optional<HelpChat> findByIdAndUserId(UUID id, UUID userId) {
        return jpa.findByIdAndUserId(id, userId).map(this::toDomain);
    }
    private HelpChat toDomain(HelpChatEntity entity) {
        return HelpChat.rehydrate(entity.getId(), entity.getUserId(), entity.getTitle(),
            entity.getSubtitle(), entity.getLastMessageAt());
    }
}
