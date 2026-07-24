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
    String companyInfo
) implements DomainEvent {

    public static UserAccessStateChangedEvent of(UUID publicUserId, String role, boolean active,
                                                 String fullName, String avatarUrl,
                                                 String city, String country,
                                                 String companyName, String companyInfo) {
        return new UserAccessStateChangedEvent(
            UUID.randomUUID(), Instant.now(), publicUserId, role, active,
            fullName, avatarUrl, city, country, companyName, companyInfo);
    }

    @Override
    public String eventType() {
        return "identity.user.access-state-changed.v1";
    }
}
