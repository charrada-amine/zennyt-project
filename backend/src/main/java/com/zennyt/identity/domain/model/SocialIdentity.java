package com.zennyt.identity.domain.model;

import java.time.Instant;

public record SocialIdentity(
    Long id,
    Long userId,
    SocialProvider provider,
    String providerSubject,
    String email,
    Instant createdAt,
    Instant updatedAt
) {
    public static SocialIdentity create(Long userId, SocialProvider provider,
                                        String providerSubject, String email) {
        Instant now = Instant.now();
        return new SocialIdentity(null, userId, provider, providerSubject, email, now, now);
    }
}
