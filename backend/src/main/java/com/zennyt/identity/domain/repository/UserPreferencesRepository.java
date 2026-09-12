package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.UserPreferences;

import java.util.Optional;

public interface UserPreferencesRepository {
    Optional<UserPreferences> findByUserId(Long userId);
    UserPreferences save(UserPreferences preferences);
}
