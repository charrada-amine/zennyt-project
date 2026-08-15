package com.zennyt.engagement.application.usecase;

import com.zennyt.engagement.application.port.RealtimeEventPort;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.MessageRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SendMessageUseCase {
    private static final String MESSAGE_QUEUE = "/queue/messages";

    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final NotificationRepository notifications;
    private final RealtimeEventPort realtime;

    @Transactional
    public Conversation.Message execute(UUID actorId, UUID conversationId, String content,
                                        MessageContentType contentType, String attachmentUrl) {
        Conversation conversation = conversations.findByIdAndParticipantId(conversationId, actorId)
            .orElseThrow(() -> new NotFoundException("Conversation introuvable"));
        Conversation.Message message = conversation.recordMessage(
            actorId, content, contentType, attachmentUrl);
        conversations.save(conversation);
        Conversation.Message saved = messages.save(message);
        UUID recipientId = conversation.counterpartIdFor(actorId);
        realtime.sendToUser(recipientId, MESSAGE_QUEUE, toPayload(saved));
        notifications.save(Notification.create(
            recipientId, NotificationType.NEW_MESSAGE, "Nouveau message", content,
            "/conversations/" + conversation.id()));
        return saved;
    }

    /** Payload aligné sur le schéma OpenAPI Message, consommé par le client. */
    private static Map<String, Object> toPayload(Conversation.Message message) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("id", message.id().toString());
        payload.put("conversationId", message.conversationId().toString());
        payload.put("senderId", message.senderId().toString());
        payload.put("senderRole", message.senderRole().name());
        payload.put("content", message.content());
        payload.put("contentType", message.contentType().name());
        payload.put("attachmentUrl", message.attachmentUrl());
        payload.put("sentAt", message.sentAt().toString());
        payload.put("readAt", message.readAt() == null ? null : message.readAt().toString());
        return payload;
    }
}
