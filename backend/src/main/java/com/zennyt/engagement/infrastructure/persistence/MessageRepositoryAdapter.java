package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class MessageRepositoryAdapter implements MessageRepository {
    private final JpaMessageRepository jpa;

    @Override
    public Conversation.Message save(Conversation.Message message) {
        return toDomain(jpa.save(new MessageEntity(
            message.id(), message.conversationId(), message.senderId(), message.senderRole(),
            message.content(), message.contentType(), message.attachmentUrl(),
            message.sentAt(), message.readAt())));
    }

    @Override
    public List<Conversation.Message> findRecent(UUID conversationId, UUID beforeMessageId, int size) {
        var pageable = PageRequest.of(0, size);
        var entities = beforeMessageId == null
            ? jpa.findByConversationIdOrderBySentAtDescIdDesc(conversationId, pageable)
            : jpa.findBefore(conversationId, beforeMessageId, pageable);
        return entities.stream().map(this::toDomain).toList();
    }

    @Override
    public void markReceivedMessagesAsRead(UUID conversationId, UUID readerId, Instant readAt) {
        jpa.markReceivedAsRead(conversationId, readerId, readAt);
    }

    private Conversation.Message toDomain(MessageEntity entity) {
        return Conversation.Message.rehydrate(entity.getId(), entity.getConversationId(),
            entity.getSenderId(), entity.getSenderRole(), entity.getContent(),
            entity.getContentType(), entity.getAttachmentUrl(), entity.getSentAt(),
            entity.getReadAt());
    }
}
