package com.zennyt.identity.application;

import com.zennyt.identity.application.port.EmailPort;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.application.port.SocialIdentityVerifier;
import com.zennyt.identity.domain.model.PasswordResetCode;
import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.model.SocialIdentity;
import com.zennyt.identity.domain.model.SocialProvider;
import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.PasswordResetCodeRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.SocialIdentityRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import com.zennyt.shared.domain.vo.Email;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class AuthService {
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final int MAX_RESET_ATTEMPTS = 5;

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final TokenService tokens;
    private final SocialIdentityRepository socialIdentities;
    private final SocialIdentityVerifier socialIdentityVerifier;
    private final PasswordResetCodeRepository passwordResetCodes;
    private final EmailPort email;
    private final Duration resetCodeTtl;
    private final ApplicationEventPublisher events;
    private final OnboardingRepository onboarding;
    private final ProfileRepository profiles;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthService(UserRepository users, PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager, TokenService tokens,
                       SocialIdentityRepository socialIdentities,
                       SocialIdentityVerifier socialIdentityVerifier,
                       PasswordResetCodeRepository passwordResetCodes, EmailPort email,
                       @Value("${identity.password-reset.code-ttl:PT10M}") Duration resetCodeTtl,
                       ApplicationEventPublisher events, OnboardingRepository onboarding,
                       ProfileRepository profiles) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.tokens = tokens;
        this.socialIdentities = socialIdentities;
        this.socialIdentityVerifier = socialIdentityVerifier;
        this.passwordResetCodes = passwordResetCodes;
        this.email = email;
        this.resetCodeTtl = resetCodeTtl;
        this.events = events;
        this.onboarding = onboarding;
        this.profiles = profiles;
    }

    @Transactional
    public TokenService.TokenPair register(String firstName, String lastName, String email,
                                           String phoneNumber, String password, Role role,
                                           String city, String country, String address,
                                           boolean termsAccepted) {
        if (role == Role.ADMIN) {
            throw new IllegalArgumentException("Le rôle administrateur ne peut pas être créé publiquement");
        }
        Email normalizedEmail = new Email(email);
        if (users.existsByEmail(normalizedEmail.value())) {
            throw new ConflictException("Un compte existe déjà pour cet email");
        }
        User user = User.register(firstName, lastName, normalizedEmail, phoneNumber,
            passwordEncoder.encode(password), role, city, country, address, termsAccepted);
        User saved = users.save(user);
        publishAccessState(saved);
        return tokens.issue(saved);
    }

    @Transactional
    public TokenService.TokenPair login(String email, String password) {
        authenticationManager.authenticate(
            UsernamePasswordAuthenticationToken.unauthenticated(email, password));
        User user = users.findByEmail(email)
            .orElseThrow(() -> new IllegalArgumentException("Identifiants invalides"));
        publishAccessState(user);
        return tokens.issue(user);
    }

    @Transactional
    public TokenService.TokenPair socialLogin(SocialProvider provider, String idToken,
                                              String firstName, String lastName, Role role,
                                              boolean termsAccepted) {
        SocialIdentityVerifier.VerifiedIdentity verified =
            socialIdentityVerifier.verify(provider, idToken);

        SocialIdentity existingIdentity = socialIdentities
            .findByProviderAndSubject(provider, verified.subject())
            .orElse(null);
        if (existingIdentity != null) {
            User user = requireActiveUser(existingIdentity.userId());
            return tokens.issue(user);
        }

        if (!verified.emailVerified() || verified.email() == null || verified.email().isBlank()) {
            throw new BadCredentialsException("A verified email is required");
        }

        Email email = new Email(verified.email());
        User user = users.findByEmail(email.value()).orElse(null);
        if (user == null) {
            if (role == null || role == Role.ADMIN) {
                throw new IllegalArgumentException("Un rôle public valide est obligatoire");
            }
            if (!termsAccepted) {
                throw new IllegalArgumentException(
                    "Les conditions d'utilisation doivent être acceptées");
            }
            String resolvedFirstName = firstNonBlank(firstName, verified.firstName());
            String resolvedLastName = firstNonBlank(lastName, verified.lastName());
            if (resolvedFirstName == null || resolvedLastName == null) {
                throw new IllegalArgumentException(
                    "Le prénom et le nom sont obligatoires pour créer le compte");
            }
            String passwordHash = passwordEncoder.encode(UUID.randomUUID().toString());
            user = users.save(User.registerSocial(resolvedFirstName, resolvedLastName, email,
                passwordHash, role, verified.profileImageUrl(), true));
        } else {
            if (!user.active()) {
                throw new BadCredentialsException("Compte inactif");
            }
            if (!user.emailVerified()) {
                user.markEmailVerified();
                user = users.save(user);
            }
        }

        socialIdentities.save(SocialIdentity.create(
            user.id(), provider, verified.subject(), email.value()));
        publishAccessState(user);
        return tokens.issue(user);
    }

    @Transactional
    public TokenService.TokenPair refresh(String refreshToken) {
        return tokens.rotate(refreshToken);
    }

    @Transactional
    public void logout(String refreshToken) {
        tokens.revoke(refreshToken);
    }

    /** Changement de mot de passe par un utilisateur connecté (vérifie le mot de passe actuel). */
    @Transactional
    public void changePassword(UUID publicId, String currentPassword, String newPassword) {
        User user = users.findByPublicId(publicId)
            .filter(User::active)
            .orElseThrow(() -> new BadCredentialsException("Compte inactif ou introuvable"));
        if (!passwordEncoder.matches(currentPassword, user.passwordHash())) {
            throw new BadCredentialsException("Mot de passe actuel incorrect");
        }
        user.changePassword(passwordEncoder.encode(newPassword));
        users.save(user);
        tokens.revokeAll(user.id());
    }

    /**
     * Démarre une réinitialisation : génère un code OTP, l'envoie par e-mail.
     * Ne révèle jamais si l'e-mail existe (anti-énumération) : renvoie toujours sans erreur.
     */
    @Transactional
    public void forgotPassword(String rawEmail) {
        Email normalizedEmail;
        try {
            normalizedEmail = new Email(rawEmail);
        } catch (RuntimeException invalid) {
            return;
        }
        users.findByEmail(normalizedEmail.value()).filter(User::active).ifPresent(user -> {
            passwordResetCodes.invalidateAllForUser(user.id());
            String code = generateCode();
            passwordResetCodes.save(PasswordResetCode.issue(user.id(), hash(code),
                Instant.now().plus(resetCodeTtl)));
            // Un échec d'envoi (fournisseur indisponible/mal configuré) ne doit ni propager une
            // erreur ni révéler que le compte existe : on journalise et on renvoie quand même 202.
            try {
                email.sendPasswordResetCode(user.email().value(), user.firstName(), code);
            } catch (RuntimeException ex) {
                log.warn("Échec de l'envoi du code de réinitialisation pour l'utilisateur {}",
                    user.id(), ex);
            }
        });
    }

    /** Termine la réinitialisation : valide le code OTP et applique le nouveau mot de passe. */
    @Transactional
    public void resetPassword(String rawEmail, String code, String newPassword) {
        User user = users.findByEmail(new Email(rawEmail).value())
            .filter(User::active)
            .orElseThrow(() -> new BadCredentialsException("Code de réinitialisation invalide"));
        PasswordResetCode resetCode = passwordResetCodes.findLatestActiveByUserId(user.id())
            .filter(value -> value.usableAt(Instant.now()))
            .orElseThrow(() -> new BadCredentialsException("Code de réinitialisation invalide ou expiré"));
        if (resetCode.attempts() >= MAX_RESET_ATTEMPTS) {
            throw new BadCredentialsException("Trop de tentatives, demandez un nouveau code");
        }
        if (!MessageDigest.isEqual(hash(code).getBytes(StandardCharsets.UTF_8),
                resetCode.codeHash().getBytes(StandardCharsets.UTF_8))) {
            passwordResetCodes.save(resetCode.withIncrementedAttempts());
            throw new BadCredentialsException("Code de réinitialisation invalide");
        }
        passwordResetCodes.save(resetCode.consume());
        user.changePassword(passwordEncoder.encode(newPassword));
        users.save(user);
        tokens.revokeAll(user.id());
    }

    private String generateCode() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }

    private String hash(String value) {
        try {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 indisponible", ex);
        }
    }

    private User requireActiveUser(Long userId) {
        return users.findById(userId)
            .filter(User::active)
            .orElseThrow(() -> new BadCredentialsException("Compte inactif ou introuvable"));
    }

    private void publishAccessState(User user) {
        String companyName = null;
        String companyInfo = null;
        if (user.role() == Role.RECRUITER) {
            var recruiter = onboarding.findRecruiterByUserId(user.id()).orElse(null);
            if (recruiter != null) {
                companyName = recruiter.companyName();
                companyInfo = recruiter.aboutMe();
            }
        }
        Profile profile = user.role() == Role.RECRUITER ? null
            : profiles.findByUserId(user.id()).orElse(null);
        events.publishEvent(UserAccessStateChangedEvent.of(
            user.publicId(), user.role().name(), user.active(),
            user.firstName() + " " + user.lastName(), user.profileImageUrl(),
            user.city(), user.country(), companyName, companyInfo,
            profile != null && profile.workplaceType() != null ? profile.workplaceType().name() : null,
            profile != null && profile.jobType() != null ? profile.jobType().name() : null,
            profile != null ? profile.targetJobLocation() : null,
            profile != null ? profile.openInternationally() : null,
            profile != null ? profile.yearsOfExperience() : null,
            profile != null ? profile.lookingFor() : null));
    }

    private static String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null || fallback.isBlank() ? null : fallback.trim();
    }
}
