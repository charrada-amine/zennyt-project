package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.PageSlice;

import java.util.Optional;
import java.util.UUID;

public interface ConversationRepository {
    Conversation save(Conversation conversation);
    Optional<Conversation> findByIdAndParticipantId(UUID id, UUID participantId);
    Optional<Conversation> findByApplicationIdAndParticipantId(UUID applicationId, UUID participantId);
    PageSlice<Conversation> findByParticipantId(UUID participantId, int page, int size);
}
