package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.SocialIdentity;
import com.zennyt.identity.domain.model.SocialProvider;
import com.zennyt.identity.domain.repository.SocialIdentityRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class SocialIdentityRepositoryAdapter implements SocialIdentityRepository {
    private final JpaSocialIdentityRepository jpa;

    public SocialIdentityRepositoryAdapter(JpaSocialIdentityRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public SocialIdentity save(SocialIdentity identity) {
        return toDomain(jpa.save(new SocialIdentityEntity(
            identity.id(), identity.userId(), identity.provider(), identity.providerSubject(),
            identity.email(), identity.createdAt(), identity.updatedAt())));
    }

    @Override
    public Optional<SocialIdentity> findByProviderAndSubject(
        SocialProvider provider, String subject) {
        return jpa.findByProviderAndProviderSubject(provider, subject).map(this::toDomain);
    }

    private SocialIdentity toDomain(SocialIdentityEntity entity) {
        return new SocialIdentity(entity.getId(), entity.getUserId(), entity.getProvider(),
            entity.getProviderSubject(), entity.getEmail(), entity.getCreatedAt(),
            entity.getUpdatedAt());
    }
}
