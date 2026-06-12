package com.zennyt.identity.domain.model;

import java.time.Instant;
import java.time.LocalDate;

public record Education(Long id, String degree, String school, String fieldOfStudy,
                        String description, LocalDate startDate, LocalDate endDate,
                        Instant createdAt, Instant updatedAt) {
    public Education {
        if (degree == null || degree.isBlank()) {
            throw new IllegalArgumentException("Le diplôme est obligatoire");
        }
        degree = degree.trim();
        if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
            throw new IllegalArgumentException("La date de fin doit suivre la date de début");
        }
    }

    public static Education create(String degree, String school, String fieldOfStudy,
                                   String description, LocalDate startDate, LocalDate endDate) {
        Instant now = Instant.now();
        return new Education(null, degree, school, fieldOfStudy, description, startDate, endDate,
            now, now);
    }
}
