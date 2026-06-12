package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.SocialProvider;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

interface JpaSocialIdentityRepository extends JpaRepository<SocialIdentityEntity, Long> {
    Optional<SocialIdentityEntity> findByProviderAndProviderSubject(
        SocialProvider provider, String providerSubject);
}
