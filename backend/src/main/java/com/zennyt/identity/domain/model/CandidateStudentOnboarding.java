package com.zennyt.identity.domain.model;

import java.time.Instant;

public record CandidateStudentOnboarding(
    Long id,
    Long userId,
    String school,
    String educationLevel,
    String fieldOfWork,
    String lastPositionHeld,
    Integer yearsOfExperience,
    String cvFileUrl,
    Instant createdAt,
    Instant updatedAt
) {
    public CandidateStudentOnboarding {
        if (yearsOfExperience != null && yearsOfExperience < 0) {
            throw new IllegalArgumentException("Les années d'expérience doivent être positives");
        }
    }

    public static CandidateStudentOnboarding create(Long userId, String school, String educationLevel,
                                                     String fieldOfWork, String lastPositionHeld,
                                                     Integer yearsOfExperience, String cvFileUrl) {
        Instant now = Instant.now();
        return new CandidateStudentOnboarding(null, userId, school, educationLevel, fieldOfWork,
            lastPositionHeld, yearsOfExperience, cvFileUrl, now, now);
    }
}
