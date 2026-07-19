package com.zennyt.engagement.domain.repository;

import com.zennyt.engagement.domain.model.UserPostPreferences;

import java.util.Optional;
import java.util.UUID;

public interface UserPostPreferencesRepository {
    UserPostPreferences save(UserPostPreferences preferences);
    Optional<UserPostPreferences> findByUserId(UUID userId);
}
