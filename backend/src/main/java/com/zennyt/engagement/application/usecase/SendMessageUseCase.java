package com.zennyt.engagement.application.usecase;

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

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SendMessageUseCase {
    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final NotificationRepository notifications;

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
        notifications.save(Notification.create(
            recipientId, NotificationType.NEW_MESSAGE, "Nouveau message", content,
            "/conversations/" + conversation.id()));
        return saved;
    }
}
