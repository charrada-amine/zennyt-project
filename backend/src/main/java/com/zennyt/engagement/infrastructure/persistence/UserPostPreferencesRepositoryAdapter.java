package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.domain.model.UserPostPreferences;
import com.zennyt.engagement.domain.repository.UserPostPreferencesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class UserPostPreferencesRepositoryAdapter implements UserPostPreferencesRepository {
    private final JpaUserPostPreferencesRepository jpa;
    @Override public UserPostPreferences save(UserPostPreferences preferences) {
        return toDomain(jpa.save(new UserPostPreferencesEntity(preferences.userId(),
            new LinkedHashSet<>(preferences.hiddenPostIds()),
            new LinkedHashSet<>(preferences.blockedAuthorIds()))));
    }
    @Override public Optional<UserPostPreferences> findByUserId(UUID userId) {
        return jpa.findById(userId).map(this::toDomain);
    }
    private UserPostPreferences toDomain(UserPostPreferencesEntity entity) {
        return new UserPostPreferences(entity.getUserId(),
            entity.getHiddenPostIds().stream().toList(),
            entity.getBlockedAuthorIds().stream().toList());
    }
}
