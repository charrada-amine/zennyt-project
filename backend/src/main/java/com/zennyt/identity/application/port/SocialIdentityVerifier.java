package com.zennyt.identity.application.port;

import com.zennyt.identity.domain.model.SocialProvider;

public interface SocialIdentityVerifier {
    VerifiedIdentity verify(SocialProvider provider, String idToken);

    record VerifiedIdentity(
        String subject,
        String email,
        boolean emailVerified,
        String firstName,
        String lastName,
        String profileImageUrl
    ) {}
}
