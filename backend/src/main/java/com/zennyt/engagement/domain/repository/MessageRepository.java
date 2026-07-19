package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Conversation;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface MessageRepository {
    Conversation.Message save(Conversation.Message message);
    List<Conversation.Message> findRecent(UUID conversationId, UUID beforeMessageId, int size);
    void markReceivedMessagesAsRead(UUID conversationId, UUID readerId, Instant readAt);
}
