package com.zennyt.recruitment.api.dto;

import com.zennyt.recruitment.domain.vo.SwipeDirection;
import java.util.UUID;

/**
 * DTO de requête pour un swipe.
 *
 * <p>L'identité du swiper vient exclusivement du contexte d'authentification.
 * {@code jobOfferId} est requis lorsqu'un recruteur swipe un
 * candidat ({@code targetType = CANDIDATE}) ; pour un swipe candidat il est déduit
 * de {@code targetId}. {@code direction} accepte LIKE/PASS ou les alias frontend
 * RIGHT/LEFT. Les champs purement décoratifs envoyés par le client (jobTitle,
 * candidateName…) sont ignorés.
 */
public record SwipeRequest(UUID targetId, String targetType,
                           UUID jobOfferId, String direction) {

    public SwipeDirection resolvedDirection() {
        if (direction == null) throw new IllegalArgumentException("direction est obligatoire");
        return switch (direction.toUpperCase()) {
            case "LIKE", "RIGHT" -> SwipeDirection.LIKE;
            case "PASS", "LEFT" -> SwipeDirection.PASS;
            default -> throw new IllegalArgumentException("direction inconnue : " + direction);
        };
    }
}
