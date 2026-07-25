package com.zennyt.recruitment.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Projection locale de l'état d'accès Identity, avec le strict nécessaire
 * d'affichage (nom, avatar, localisation) pour enrichir les listes candidat/
 * recruteur sans appel direct au module Identity.
 */
public record RecruitmentActor(
    UUID publicUserId,
    String role,
    boolean active,
    String fullName,
    String avatarUrl,
    String city,
    String country,
    String companyName,
    String companyInfo,
    Instant lastEventAt,
    UUID lastEventId
) {
    public RecruitmentActor apply(String newRole, boolean newActive,
                                  String newFullName, String newAvatarUrl,
                                  String newCity, String newCountry,
                                  String newCompanyName, String newCompanyInfo,
                                  Instant eventAt, UUID eventId) {
        return new RecruitmentActor(publicUserId, newRole, newActive,
            newFullName, newAvatarUrl, newCity, newCountry,
            newCompanyName, newCompanyInfo, eventAt, eventId);
    }
}
