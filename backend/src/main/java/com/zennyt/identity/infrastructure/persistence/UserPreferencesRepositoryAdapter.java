package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.UserPreferences;
import com.zennyt.identity.domain.repository.UserPreferencesRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class UserPreferencesRepositoryAdapter implements UserPreferencesRepository {
    private final JpaUserPreferencesRepository jpa;

    public UserPreferencesRepositoryAdapter(JpaUserPreferencesRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Optional<UserPreferences> findByUserId(Long userId) {
        return jpa.findById(userId).map(this::toDomain);
    }

    @Override
    public UserPreferences save(UserPreferences preferences) {
        return toDomain(jpa.save(new UserPreferencesEntity(
            preferences.userId(), preferences.notificationsEnabled(), preferences.highContrast(),
            preferences.textSizePx(), preferences.updatedAt())));
    }

    private UserPreferences toDomain(UserPreferencesEntity entity) {
        return new UserPreferences(entity.getUserId(), entity.isNotificationsEnabled(),
            entity.isHighContrast(), entity.getTextSizePx(), entity.getUpdatedAt());
    }
}
