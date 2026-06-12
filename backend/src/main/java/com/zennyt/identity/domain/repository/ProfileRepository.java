package com.zennyt.identity.domain.repository;

import com.zennyt.identity.domain.model.Profile;

import java.util.Optional;

public interface ProfileRepository {
    Profile save(Profile profile);
    Optional<Profile> findByUserId(Long userId);
    Optional<Profile> findById(Long id);
}
