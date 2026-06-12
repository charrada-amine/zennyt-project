package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.SocialIdentity;
import com.zennyt.identity.domain.model.SocialProvider;

import java.util.Optional;

public interface SocialIdentityRepository {
    SocialIdentity save(SocialIdentity identity);
    Optional<SocialIdentity> findByProviderAndSubject(SocialProvider provider, String subject);
}
