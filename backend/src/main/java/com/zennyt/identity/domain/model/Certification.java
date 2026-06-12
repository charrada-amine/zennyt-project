package com.zennyt.identity.domain.model;

import java.time.Instant;
import java.time.LocalDate;

public record Certification(Long id, String title, String issuer, LocalDate completionDate,
                            String credentialId, String credentialUrl,
                            Instant createdAt, Instant updatedAt) {
    public Certification {
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Le titre de la certification est obligatoire");
        }
        title = title.trim();
    }

    public static Certification create(String title, String issuer, LocalDate completionDate,
                                       String credentialId, String credentialUrl) {
        Instant now = Instant.now();
        return new Certification(null, title, issuer, completionDate, credentialId, credentialUrl,
            now, now);
    }
}
