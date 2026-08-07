package com.zennyt.identity.domain.event;

import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/**
 * État d'accès publié aux autres bounded contexts.
 *
 * <p>Porte aussi le strict nécessaire d'affichage (nom, avatar, localisation)
 * pour que recruitment puisse enrichir ses listes candidat/recruteur sans
 * appel direct au module Identity — juste des données publiques de profil,
 * pas de PII sensible (email, téléphone, adresse).
 *
 * <p>Depuis "Recommended for you" (filtrage de pertinence) : porte aussi les
 * préférences de recherche d'emploi du candidat (null pour un recruteur, ou
 * si non renseigné) — {@code workplaceType}/{@code jobType} restent les noms
 * bruts des enums {@code identity.domain.model} (ex. {@code "ONSITE"},
 * {@code "FREELANCE"}) plutôt que les enums recruitment eux-mêmes : le
 * rapprochement entre les deux vocabulaires (différents) se fait côté
 * recruitment, pas ici.
 */
public record UserAccessStateChangedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID publicUserId,
    String role,
    boolean active,
    String fullName,
    String avatarUrl,
    String city,
    String country,
    String companyName,
    String companyInfo,
    String workplaceTypePreference,
    String jobTypePreference,
    String targetJobLocation,
    Boolean openInternationally,
    Integer yearsOfExperience,
    String lookingFor
) implements DomainEvent {

    public static UserAccessStateChangedEvent of(UUID publicUserId, String role, boolean active,
                                                 String fullName, String avatarUrl,
                                                 String city, String country,
                                                 String companyName, String companyInfo,
                                                 String workplaceTypePreference, String jobTypePreference,
                                                 String targetJobLocation, Boolean openInternationally,
                                                 Integer yearsOfExperience, String lookingFor) {
        return new UserAccessStateChangedEvent(
            UUID.randomUUID(), Instant.now(), publicUserId, role, active,
            fullName, avatarUrl, city, country, companyName, companyInfo,
            workplaceTypePreference, jobTypePreference, targetJobLocation,
            openInternationally, yearsOfExperience, lookingFor);
    }

    @Override
    public String eventType() {
        return "identity.user.access-state-changed.v1";
    }
}
