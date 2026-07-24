package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;

import java.time.Instant;
import java.util.UUID;

public record MessageResponse(String id, String conversationId, UUID senderId,
                              MessageSenderRole senderRole, String content,
                              MessageContentType contentType, String attachmentUrl,
                              Instant sentAt, Instant readAt) {
    public static MessageResponse from(Conversation.Message message) {
        return new MessageResponse(message.id().toString(), message.conversationId().toString(),
            message.senderId(), message.senderRole(), message.content(), message.contentType(),
            message.attachmentUrl(), message.sentAt(), message.readAt());
    }
}
