package com.zennyt.engagement.domain;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.vo.MessageContentType;
import com.zennyt.engagement.domain.vo.MessageSenderRole;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class ConversationTest {

    private final UUID applicationId = UUID.randomUUID();
    private final UUID jobOfferId = UUID.randomUUID();
    private final UUID candidateId = UUID.randomUUID();
    private final UUID recruiterId = UUID.randomUUID();

    @Test
    void create_initializes_a_shared_conversation_without_unread_messages() {
        Conversation conversation = createConversation();

        assertNotNull(conversation.id());
        assertEquals(applicationId, conversation.applicationId());
        assertEquals(jobOfferId, conversation.jobOfferId());
        assertEquals(candidateId, conversation.candidateId());
        assertEquals(recruiterId, conversation.recruiterId());
        assertEquals("Backend Engineer", conversation.jobTitle());
        assertEquals("", conversation.lastMessagePreview());
        assertNull(conversation.lastMessageAt());
        assertEquals(0, conversation.unreadCountFor(candidateId));
        assertEquals(0, conversation.unreadCountFor(recruiterId));
    }

    @Test
    void create_rejects_a_conversation_with_the_same_participant_twice() {
        assertThrows(IllegalArgumentException.class, () -> Conversation.create(
            applicationId, jobOfferId, candidateId, candidateId, "Backend Engineer"));
    }

    @Test
    void candidate_message_derives_role_and_only_increments_recruiter_counter() {
        Conversation conversation = createConversation();

        Conversation.Message message = conversation.recordMessage(
            candidateId, "Hello", null, null);

        assertEquals(MessageSenderRole.CANDIDATE, message.senderRole());
        assertEquals(MessageContentType.TEXT, message.contentType());
        assertEquals(0, conversation.unreadCountFor(candidateId));
        assertEquals(1, conversation.unreadCountFor(recruiterId));
        assertEquals(message.sentAt(), conversation.lastMessageAt());
        assertEquals("Hello", conversation.lastMessagePreview());
    }

    @Test
    void recruiter_message_only_increments_candidate_counter() {
        Conversation conversation = createConversation();

        Conversation.Message message = conversation.recordMessage(
            recruiterId, "Welcome", MessageContentType.SYSTEM, null);

        assertEquals(MessageSenderRole.RECRUITER, message.senderRole());
        assertEquals(1, conversation.unreadCountFor(candidateId));
        assertEquals(0, conversation.unreadCountFor(recruiterId));
    }

    @Test
    void outsider_cannot_read_or_write_the_conversation() {
        UUID outsiderId = UUID.randomUUID();
        Conversation conversation = createConversation();

        assertFalse(conversation.isParticipant(outsiderId));
        assertThrows(IllegalArgumentException.class,
            () -> conversation.recordMessage(outsiderId, "Intrusion", MessageContentType.TEXT, null));
        assertThrows(IllegalArgumentException.class, () -> conversation.markAsReadBy(outsiderId));
        assertThrows(IllegalArgumentException.class, () -> conversation.counterpartIdFor(outsiderId));
    }

    @Test
    void mark_as_read_resets_only_the_current_participant_counter() {
        Conversation conversation = createConversation();
        conversation.recordMessage(candidateId, "One", MessageContentType.TEXT, null);
        conversation.recordMessage(recruiterId, "Two", MessageContentType.TEXT, null);

        conversation.markAsReadBy(candidateId);

        assertEquals(0, conversation.unreadCountFor(candidateId));
        assertEquals(1, conversation.unreadCountFor(recruiterId));
    }

    @Test
    void last_message_preview_handles_exact_limit_and_truncation() {
        Conversation conversation = createConversation();
        String exactlyOneHundred = "a".repeat(100);

        conversation.recordMessage(candidateId, exactlyOneHundred, MessageContentType.TEXT, null);
        assertEquals(exactlyOneHundred, conversation.lastMessagePreview());

        conversation.recordMessage(recruiterId, "b".repeat(101), MessageContentType.TEXT, null);
        assertEquals("b".repeat(100) + "...", conversation.lastMessagePreview());
    }

    @Test
    void blank_message_is_rejected_without_changing_counters() {
        Conversation conversation = createConversation();

        assertThrows(IllegalArgumentException.class,
            () -> conversation.recordMessage(candidateId, "  ", MessageContentType.TEXT, null));
        assertEquals(0, conversation.unreadCountFor(recruiterId));
    }

    @Test
    void rehydrate_preserves_persisted_state() {
        UUID id = UUID.randomUUID();
        Instant lastMessageAt = Instant.parse("2026-07-18T08:00:00Z");

        Conversation conversation = Conversation.rehydrate(
            id, applicationId, jobOfferId, candidateId, recruiterId, "Backend Engineer",
            "Persisted", lastMessageAt, 2, 3);

        assertEquals(id, conversation.id());
        assertEquals(lastMessageAt, conversation.lastMessageAt());
        assertEquals(2, conversation.unreadCountFor(candidateId));
        assertEquals(3, conversation.unreadCountFor(recruiterId));
        assertEquals(recruiterId, conversation.counterpartIdFor(candidateId));
        assertEquals(candidateId, conversation.counterpartIdFor(recruiterId));
    }

    private Conversation createConversation() {
        return Conversation.create(
            applicationId, jobOfferId, candidateId, recruiterId, "Backend Engineer");
    }
}
