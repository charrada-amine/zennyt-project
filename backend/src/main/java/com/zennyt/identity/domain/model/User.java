package com.zennyt.identity.domain.model;

import com.zennyt.shared.domain.vo.Email;
import lombok.Getter;
import lombok.experimental.Accessors;

import java.time.Instant;
import java.util.UUID;

@Getter
@Accessors(fluent = true)
public class User {
    private final Long id;
    private final UUID publicId;
    private String firstName;
    private String lastName;
    private Email email;
    private String phoneNumber;
    private String passwordHash;
    private Role role;
    private String city;
    private String country;
    private String address;
    private String profileImageUrl;
    private String profileImagePublicId;
    private final boolean termsAccepted;
    private boolean emailVerified;
    private boolean active;
    private Instant deletedAt;
    private final Instant createdAt;
    private Instant updatedAt;

    private User(Long id, UUID publicId, String firstName, String lastName, Email email,
                 String phoneNumber, String passwordHash, Role role, String city, String country,
                 String address, String profileImageUrl, String profileImagePublicId,
                 boolean termsAccepted, boolean emailVerified, boolean active, Instant deletedAt,
                 Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.publicId = publicId;
        this.firstName = requireText(firstName, "Le prénom est obligatoire");
        this.lastName = requireText(lastName, "Le nom est obligatoire");
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.passwordHash = requireText(passwordHash, "Le mot de passe chiffré est obligatoire");
        this.role = role;
        this.city = city;
        this.country = country;
        this.address = address;
        this.profileImageUrl = profileImageUrl;
        this.profileImagePublicId = profileImagePublicId;
        this.termsAccepted = termsAccepted;
        this.emailVerified = emailVerified;
        this.active = active;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static User register(String firstName, String lastName, Email email, String phoneNumber,
                                String passwordHash, Role role, String city, String country,
                                String address, boolean termsAccepted) {
        if (!termsAccepted) {
            throw new IllegalArgumentException("Les conditions d'utilisation doivent être acceptées");
        }
        Instant now = Instant.now();
        return new User(null, UUID.randomUUID(), firstName, lastName, email, phoneNumber,
            passwordHash, role, city, country, address, null, null, true, false, true, null, now, now);
    }

    public static User registerSocial(String firstName, String lastName, Email email,
                                      String passwordHash, Role role, String profileImageUrl,
                                      boolean termsAccepted) {
        if (!termsAccepted) {
            throw new IllegalArgumentException("Les conditions d'utilisation doivent être acceptées");
        }
        Instant now = Instant.now();
        return new User(null, UUID.randomUUID(), firstName, lastName, email, null,
            passwordHash, role, null, null, null, profileImageUrl, null, true, true, true, null, now, now);
    }

    public static User rehydrate(Long id, UUID publicId, String firstName, String lastName,
                                 Email email, String phoneNumber, String passwordHash, Role role,
                                 String city, String country, String address, String profileImageUrl,
                                 String profileImagePublicId, boolean termsAccepted,
                                 boolean emailVerified, boolean active, Instant deletedAt,
                                 Instant createdAt, Instant updatedAt) {
        return new User(id, publicId, firstName, lastName, email, phoneNumber, passwordHash, role,
            city, country, address, profileImageUrl, profileImagePublicId, termsAccepted,
            emailVerified, active, deletedAt, createdAt, updatedAt);
    }

    /**
     * Met à jour les informations d'identité textuelles. L'avatar n'est volontairement
     * pas géré ici : il passe par {@link #updateAvatar} / {@link #clearAvatar} pour éviter
     * qu'une édition de profil n'efface l'image téléversée.
     */
    public void updateIdentity(String firstName, String lastName, String phoneNumber, String city,
                               String country, String address) {
        this.firstName = requireText(firstName, "Le prénom est obligatoire");
        this.lastName = requireText(lastName, "Le nom est obligatoire");
        this.phoneNumber = phoneNumber;
        this.city = city;
        this.country = country;
        this.address = address;
        this.updatedAt = Instant.now();
    }

    public void updateAvatar(String profileImageUrl, String profileImagePublicId) {
        this.profileImageUrl = profileImageUrl;
        this.profileImagePublicId = profileImagePublicId;
        this.updatedAt = Instant.now();
    }

    public void clearAvatar() {
        this.profileImageUrl = null;
        this.profileImagePublicId = null;
        this.updatedAt = Instant.now();
    }

    public void changePassword(String newPasswordHash) {
        this.passwordHash = requireText(newPasswordHash, "Le mot de passe chiffré est obligatoire");
        this.updatedAt = Instant.now();
    }

    public void deactivate() {
        this.active = false;
        this.updatedAt = Instant.now();
    }

    /**
     * Suppression logique : anonymise les données personnelles, libère l'adresse e-mail
     * (afin qu'elle puisse être réutilisée) et désactive le compte. La ligne est conservée
     * pour préserver l'intégrité référentielle (candidatures, historique).
     */
    public void softDelete() {
        Instant now = Instant.now();
        this.active = false;
        this.deletedAt = now;
        this.email = new Email("deleted+" + UUID.randomUUID() + "@deleted.zennyt.local");
        this.firstName = "Compte";
        this.lastName = "supprimé";
        this.phoneNumber = null;
        this.city = null;
        this.country = null;
        this.address = null;
        this.profileImageUrl = null;
        this.profileImagePublicId = null;
        this.updatedAt = now;
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    public void changeRole(Role role) {
        if (this.role == Role.ADMIN || role == Role.ADMIN) {
            throw new IllegalArgumentException("Le rôle administrateur ne peut pas être attribué ici");
        }
        this.role = role;
        this.updatedAt = Instant.now();
    }

    public void markEmailVerified() {
        this.emailVerified = true;
        this.updatedAt = Instant.now();
    }

    private static String requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        return value.trim();
    }
}
