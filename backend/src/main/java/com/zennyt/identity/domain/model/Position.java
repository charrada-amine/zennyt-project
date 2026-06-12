package com.zennyt.identity.domain.model;

import java.time.Instant;
import java.time.LocalDate;

public record Position(Long id, String title, String companyName, String location,
                       String description, LocalDate startDate, LocalDate endDate,
                       boolean current, Instant createdAt, Instant updatedAt) {
    public Position {
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Le titre du poste est obligatoire");
        }
        title = title.trim();
        if (current && endDate != null) {
            throw new IllegalArgumentException("Un poste actuel ne peut pas avoir de date de fin");
        }
        if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
            throw new IllegalArgumentException("La date de fin doit suivre la date de début");
        }
    }

    public static Position create(String title, String companyName, String location,
                                  String description, LocalDate startDate, LocalDate endDate,
                                  boolean current) {
        Instant now = Instant.now();
        return new Position(null, title, companyName, location, description, startDate, endDate,
            current, now, now);
    }
}
