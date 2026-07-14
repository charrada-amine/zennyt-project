package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.application.usecase.RecordSwipeUseCase;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import java.time.Instant;
import java.util.UUID;

/** DTO de réponse pour un swipe (inclut le match éventuel). */
public record SwipeResponse(UUID swipeId, SwipeDirection direction, boolean matched, UUID matchId) {
    public static SwipeResponse from(RecordSwipeUseCase.SwipeResult result) {
        return new SwipeResponse(
            result.swipe().id(), result.swipe().direction(),
            result.match() != null, result.match() != null ? result.match().id() : null
        );
    }
}
