package com.zennyt.engagement.application;

import com.zennyt.engagement.application.usecase.SendMessageUseCase;
import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.Notification;
import com.zennyt.engagement.domain.repository.ConversationRepository;
import com.zennyt.engagement.domain.repository.MessageRepository;
import com.zennyt.engagement.domain.repository.NotificationRepository;
import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.NotificationType;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SendMessageUseCaseTest {
    private final ConversationRepository conversations = mock(ConversationRepository.class);
    private final MessageRepository messages = mock(MessageRepository.class);
    private final NotificationRepository notifications = mock(NotificationRepository.class);
    private final SendMessageUseCase useCase =
        new SendMessageUseCase(conversations, messages, notifications);

    @Test
    void derives_sender_role_and_notifies_only_the_counterpart() {
        UUID candidateId = UUID.randomUUID();
        UUID recruiterId = UUID.randomUUID();
        Conversation conversation = Conversation.create(
            UUID.randomUUID(), UUID.randomUUID(), candidateId, recruiterId, "Backend Engineer");
        when(conversations.findByIdAndParticipantId(conversation.id(), candidateId))
            .thenReturn(Optional.of(conversation));
        when(messages.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(notifications.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        var result = useCase.execute(candidateId, conversation.id(), "Bonjour",
            MessageContentType.TEXT, null);

        assertThat(result.senderId()).isEqualTo(candidateId);
        assertThat(result.senderRole().name()).isEqualTo("CANDIDATE");
        assertThat(conversation.unreadCountFor(recruiterId)).isEqualTo(1);
        ArgumentCaptor<Notification> notification = ArgumentCaptor.forClass(Notification.class);
        verify(notifications).save(notification.capture());
        assertThat(notification.getValue().userId()).isEqualTo(recruiterId);
        assertThat(notification.getValue().type()).isEqualTo(NotificationType.NEW_MESSAGE);
    }

    @Test
    void hides_a_conversation_from_non_participants() {
        UUID outsiderId = UUID.randomUUID();
        UUID conversationId = UUID.randomUUID();
        when(conversations.findByIdAndParticipantId(conversationId, outsiderId))
            .thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(
            outsiderId, conversationId, "Intrusion", MessageContentType.TEXT, null))
            .isInstanceOf(NotFoundException.class);
        verify(messages, never()).save(any());
        verify(notifications, never()).save(any());
    }
}
