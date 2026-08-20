package com.zennyt.engagement.api.dto;

import com.zennyt.engagement.domain.model.CallSession;
import com.zennyt.engagement.domain.model.HelpChat;
import com.zennyt.engagement.domain.vo.CallStatus;
import com.zennyt.engagement.domain.vo.HelpChatRating;
import com.zennyt.engagement.domain.vo.CallType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.UUID;

public final class EngagementSupportDtos {
    private EngagementSupportDtos() {}
    public record CallInitiateRequest(@NotNull UUID conversationId, @NotNull CallType type, @NotBlank String webrtcOffer) {}
    public record CallJoinRequest(@NotBlank String webrtcAnswer) {}
    public record CallResponse(UUID id, UUID conversationId, CallType type, CallStatus status,
                               UUID initiatorId, UUID counterpartId, String webrtcOffer,
                               String webrtcAnswer, Instant startedAt, Instant endedAt,
                               Integer durationSeconds) {
        public static CallResponse from(CallSession value) {
            return new CallResponse(value.id(), value.conversationId(), value.type(), value.status(),
                value.initiatorId(), value.counterpartId(), value.webrtcOffer(), value.webrtcAnswer(),
                value.startedAt(), value.endedAt(), value.durationSeconds());
        }
    }
    /** Titre et sous-titre facultatifs : le menu generique n'en fournit pas. */
    public record HelpChatOpenRequest(String title, String subtitle) {}
    public record HelpChatResponse(UUID id, String title, String subtitle, Instant lastMessageAt,
                                   HelpChatRating rating, String ratingComment, Instant ratedAt) {
        public static HelpChatResponse from(HelpChat value) {
            return new HelpChatResponse(value.id(), value.title(), value.subtitle(),
                value.lastMessageAt(), value.rating(), value.ratingComment(), value.ratedAt());
        }
    }
    /** Le commentaire est facultatif : le formulaire s'ouvre apres la note et peut etre ferme. */
    public record HelpChatRatingRequest(@NotNull HelpChatRating rating, String comment) {}
    public record HelpMessageRequest(@NotBlank String text) {}
    public record HelpMessageResponse(UUID id, UUID helpChatId, String text, Instant timestamp, boolean isFromUser) {
        public static HelpMessageResponse from(HelpChat.HelpMessage value) {
            return new HelpMessageResponse(value.id(), value.helpChatId(), value.text(), value.timestamp(), value.fromUser());
        }
    }
    public record MediaUploadResponse(String url, String publicId, String resourceType) {}
}
