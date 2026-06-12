package com.zennyt.identity.domain.model;

import java.time.Instant;

public record RecruiterOnboarding(
    Long id,
    Long userId,
    String jobTitle,
    String companyName,
    String companySize,
    String companyLogoUrl,
    String fieldOfWork,
    String companyLocation,
    String companyRegistrationNumber,
    Instant createdAt,
    Instant updatedAt
) {
    public RecruiterOnboarding {
        jobTitle = requireText(jobTitle, "Le poste est obligatoire");
        companyName = requireText(companyName, "Le nom de l'entreprise est obligatoire");
        companySize = requireText(companySize, "La taille de l'entreprise est obligatoire");
        fieldOfWork = requireText(fieldOfWork, "Le secteur d'activité est obligatoire");
        companyLocation = requireText(companyLocation, "La localisation est obligatoire");
        companyRegistrationNumber = requireText(
            companyRegistrationNumber, "Le numéro d'enregistrement est obligatoire");
    }

    public static RecruiterOnboarding create(Long userId, String jobTitle, String companyName,
                                              String companySize, String companyLogoUrl,
                                              String fieldOfWork, String companyLocation,
                                              String companyRegistrationNumber) {
        Instant now = Instant.now();
        return new RecruiterOnboarding(null, userId, jobTitle, companyName, companySize,
            companyLogoUrl, fieldOfWork, companyLocation, companyRegistrationNumber, now, now);
    }

    private static String requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        return value.trim();
    }
}
