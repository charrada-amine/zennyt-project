package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

interface JpaUserRepository extends JpaRepository<UserEntity, Long> {
    Optional<UserEntity> findByEmailIgnoreCaseAndDeletedAtIsNull(String email);
    Optional<UserEntity> findByPublicIdAndDeletedAtIsNull(UUID publicId);
    boolean existsByEmailIgnoreCaseAndDeletedAtIsNull(String email);
}
