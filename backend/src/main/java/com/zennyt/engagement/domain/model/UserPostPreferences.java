package com.zennyt.engagement.domain.model;

import java.util.List;
import java.util.Objects;
import java.util.UUID;

public record UserPostPreferences(UUID userId, List<UUID> hiddenPostIds,
                                  List<UUID> blockedAuthorIds) {
    public UserPostPreferences {
        Objects.requireNonNull(userId, "userId");
        hiddenPostIds = List.copyOf(hiddenPostIds == null ? List.of() : hiddenPostIds);
        blockedAuthorIds = List.copyOf(blockedAuthorIds == null ? List.of() : blockedAuthorIds);
    }

    public static UserPostPreferences empty(UUID userId) {
        return new UserPostPreferences(userId, List.of(), List.of());
    }
}
