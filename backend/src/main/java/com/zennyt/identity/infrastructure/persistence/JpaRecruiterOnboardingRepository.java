package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

interface JpaRecruiterOnboardingRepository extends JpaRepository<RecruiterOnboardingEntity, Long> {
    Optional<RecruiterOnboardingEntity> findByUserId(Long userId);
}
