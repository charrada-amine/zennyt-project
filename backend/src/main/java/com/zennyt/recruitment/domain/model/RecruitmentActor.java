package com.zennyt.recruitment.domain.model;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.WorkplaceType;

import java.time.Instant;
import java.util.UUID;

/**
 * Projection locale de l'état d'accès Identity, avec le strict nécessaire
 * d'affichage (nom, avatar, localisation) pour enrichir les listes candidat/
 * recruteur sans appel direct au module Identity.
 *
 * <p>Depuis "Recommended for you" : porte aussi les préférences de recherche
 * d'emploi du candidat (toutes {@code null} pour un recruteur, ou si non
 * renseigné côté profil) — utilisées uniquement comme signal de tri, jamais
 * comme filtre bloquant.
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
    WorkplaceType workplaceTypePreference,
    ContractType contractTypePreference,
    String targetLocation,
    Boolean openInternationally,
    Integer yearsOfExperience,
    String lookingFor,
    String lookingForEmbedding,
    Instant lastEventAt,
    UUID lastEventId
) {
    public RecruitmentActor apply(String newRole, boolean newActive,
                                  String newFullName, String newAvatarUrl,
                                  String newCity, String newCountry,
                                  String newCompanyName, String newCompanyInfo,
                                  WorkplaceType newWorkplaceTypePreference,
                                  ContractType newContractTypePreference,
                                  String newTargetLocation, Boolean newOpenInternationally,
                                  Integer newYearsOfExperience, String newLookingFor,
                                  String newLookingForEmbedding,
                                  Instant eventAt, UUID eventId) {
        return new RecruitmentActor(publicUserId, newRole, newActive,
            newFullName, newAvatarUrl, newCity, newCountry,
            newCompanyName, newCompanyInfo,
            newWorkplaceTypePreference, newContractTypePreference, newTargetLocation,
            newOpenInternationally, newYearsOfExperience, newLookingFor, newLookingForEmbedding,
            eventAt, eventId);
    }
}
