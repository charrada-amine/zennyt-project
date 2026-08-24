package com.zennyt.identity.domain.model;

import java.time.Instant;

public record RecruiterOnboarding(
    Long id,
    Long userId,
    String jobTitle,
    String companyName,
    String companySize,
    String companyLogoUrl,
    String companyLogoPublicId,
    String fieldOfWork,
    String companyLocation,
    String companyRegistrationNumber,
    String aboutMe,
    String about,
    String mission,
    String vision,
    String keyDifferentiators,
    String cultureWorkEnvironment,
    String whyJoinUs,
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
        // New company detail fields are optional — trim if present
        about = trimOrNull(about);
        mission = trimOrNull(mission);
        vision = trimOrNull(vision);
        keyDifferentiators = trimOrNull(keyDifferentiators);
        cultureWorkEnvironment = trimOrNull(cultureWorkEnvironment);
        whyJoinUs = trimOrNull(whyJoinUs);
        aboutMe = trimOrNull(aboutMe);
    }

    public static RecruiterOnboarding create(Long userId, String jobTitle, String companyName,
                                              String companySize, String companyLogoUrl,
                                              String companyLogoPublicId, String fieldOfWork,
                                              String companyLocation,
                                              String companyRegistrationNumber,
                                              String aboutMe) {
        return create(userId, jobTitle, companyName, companySize, companyLogoUrl,
            companyLogoPublicId, fieldOfWork, companyLocation, companyRegistrationNumber,
            aboutMe, null, null, null, null, null, null);
    }

    public static RecruiterOnboarding create(Long userId, String jobTitle, String companyName,
                                              String companySize, String companyLogoUrl,
                                              String companyLogoPublicId, String fieldOfWork,
                                              String companyLocation,
                                              String companyRegistrationNumber,
                                              String aboutMe,
                                              String about, String mission, String vision,
                                              String keyDifferentiators,
                                              String cultureWorkEnvironment,
                                              String whyJoinUs) {
        Instant now = Instant.now();
        return new RecruiterOnboarding(null, userId, jobTitle, companyName, companySize,
            companyLogoUrl, companyLogoPublicId, fieldOfWork, companyLocation,
            companyRegistrationNumber, aboutMe, about, mission, vision,
            keyDifferentiators, cultureWorkEnvironment, whyJoinUs, now, now);
    }

    /** Retourne une copie avec un nouveau logo (URL + public_id), sans toucher au reste. */
    public RecruiterOnboarding withLogo(String companyLogoUrl, String companyLogoPublicId) {
        return new RecruiterOnboarding(id, userId, jobTitle, companyName, companySize,
            companyLogoUrl, companyLogoPublicId, fieldOfWork, companyLocation,
            companyRegistrationNumber, aboutMe, about, mission, vision,
            keyDifferentiators, cultureWorkEnvironment, whyJoinUs, createdAt, Instant.now());
    }

    public RecruiterOnboarding withCompanyDetails(String about, String mission, String vision,
                                                   String keyDifferentiators,
                                                   String cultureWorkEnvironment,
                                                   String whyJoinUs) {
        return new RecruiterOnboarding(id, userId, jobTitle, companyName, companySize,
            companyLogoUrl, companyLogoPublicId, fieldOfWork, companyLocation,
            companyRegistrationNumber, aboutMe, about, mission, vision,
            keyDifferentiators, cultureWorkEnvironment, whyJoinUs, createdAt, Instant.now());
    }

    public String missionVision() {
        if (mission != null && vision != null) return mission + "\n\n" + vision;
        if (mission != null) return mission;
        if (vision != null) return vision;
        return null;
    }

    private static String requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        return value.trim();
    }

    private static String trimOrNull(String value) {
        if (value == null) return null;
        String t = value.trim();
        return t.isEmpty() ? null : t;
    }
}
