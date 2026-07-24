package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.application.ActorDirectory;

import java.time.Instant;
import java.util.UUID;

public record ConversationResponse(String id, UUID applicationId, String jobTitle,
                                   String counterpartName, String counterpartPhotoUrl,
                                   String lastMessagePreview, Instant lastMessageAt,
                                   int unreadCount) {
    public static ConversationResponse from(Conversation conversation, UUID actorId, ActorDirectory actors) {
        UUID counterpartId = conversation.counterpartIdFor(actorId);
        return new ConversationResponse(conversation.id().toString(), conversation.applicationId(),
            conversation.jobTitle(), actors.displayName(counterpartId), actors.photoUrl(counterpartId), conversation.lastMessagePreview(),
            conversation.lastMessageAt(), conversation.unreadCountFor(actorId));
    }
}
