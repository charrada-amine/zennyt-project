package com.zennyt.identity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

interface JpaCandidateStudentOnboardingRepository
    extends JpaRepository<CandidateStudentOnboardingEntity, Long> {
    Optional<CandidateStudentOnboardingEntity> findByUserId(Long userId);
}
