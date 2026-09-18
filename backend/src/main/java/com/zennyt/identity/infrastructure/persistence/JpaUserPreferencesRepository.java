package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaUserPreferencesRepository extends JpaRepository<UserPreferencesEntity, Long> {
}
