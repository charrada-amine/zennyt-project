package com.zennyt.identity.domain.model;

import com.zennyt.shared.domain.vo.Email;

import java.time.Instant;
import java.util.UUID;

public class User {
    private final Long id;
    private final UUID publicId;
    private String firstName;
    private String lastName;
    private final Email email;
    private String phoneNumber;
    private final String passwordHash;
    private Role role;
    private String city;
    private String country;
    private String address;
    private String profileImageUrl;
    private final boolean termsAccepted;
    private boolean emailVerified;
    private boolean active;
    private final Instant createdAt;
    private Instant updatedAt;

    private User(Long id, UUID publicId, String firstName, String lastName, Email email,
                 String phoneNumber, String passwordHash, Role role, String city, String country,
                 String address, String profileImageUrl, boolean termsAccepted,
                 boolean emailVerified, boolean active, Instant createdAt, Instant updatedAt) {
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
        this.termsAccepted = termsAccepted;
        this.emailVerified = emailVerified;
        this.active = active;
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
            passwordHash, role, city, country, address, null, true, false, true, now, now);
    }

    public static User registerSocial(String firstName, String lastName, Email email,
                                      String passwordHash, Role role, String profileImageUrl,
                                      boolean termsAccepted) {
        if (!termsAccepted) {
            throw new IllegalArgumentException("Les conditions d'utilisation doivent être acceptées");
        }
        Instant now = Instant.now();
        return new User(null, UUID.randomUUID(), firstName, lastName, email, null,
            passwordHash, role, null, null, null, profileImageUrl, true, true, true, now, now);
    }

    public static User rehydrate(Long id, UUID publicId, String firstName, String lastName,
                                 Email email, String phoneNumber, String passwordHash, Role role,
                                 String city, String country, String address, String profileImageUrl,
                                 boolean termsAccepted, boolean emailVerified, boolean active,
                                 Instant createdAt, Instant updatedAt) {
        return new User(id, publicId, firstName, lastName, email, phoneNumber, passwordHash, role,
            city, country, address, profileImageUrl, termsAccepted, emailVerified, active,
            createdAt, updatedAt);
    }

    public void updateIdentity(String firstName, String lastName, String phoneNumber, String city,
                               String country, String address, String profileImageUrl) {
        this.firstName = requireText(firstName, "Le prénom est obligatoire");
        this.lastName = requireText(lastName, "Le nom est obligatoire");
        this.phoneNumber = phoneNumber;
        this.city = city;
        this.country = country;
        this.address = address;
        this.profileImageUrl = profileImageUrl;
        this.updatedAt = Instant.now();
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

    public Long id() { return id; }
    public UUID publicId() { return publicId; }
    public String firstName() { return firstName; }
    public String lastName() { return lastName; }
    public Email email() { return email; }
    public String phoneNumber() { return phoneNumber; }
    public String passwordHash() { return passwordHash; }
    public Role role() { return role; }
    public String city() { return city; }
    public String country() { return country; }
    public String address() { return address; }
    public String profileImageUrl() { return profileImageUrl; }
    public boolean termsAccepted() { return termsAccepted; }
    public boolean emailVerified() { return emailVerified; }
    public boolean active() { return active; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
