package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.model.Conversation;
import com.zennyt.engagement.domain.model.PageSlice;
import com.zennyt.engagement.application.ActorDirectory;

import java.util.List;
import java.util.UUID;

public record ConversationPageResponse(List<ConversationResponse> content, PageMetaResponse page) {
    public static ConversationPageResponse from(PageSlice<Conversation> slice, UUID actorId, ActorDirectory actors) {
        return new ConversationPageResponse(
            slice.content().stream().map(value -> ConversationResponse.from(value, actorId, actors)).toList(),
            PageMetaResponse.from(slice));
    }
}
