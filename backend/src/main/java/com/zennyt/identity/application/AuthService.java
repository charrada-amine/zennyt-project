package com.zennyt.identity.application;

import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.application.port.SocialIdentityVerifier;
import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.model.SocialIdentity;
import com.zennyt.identity.domain.model.SocialProvider;
import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.SocialIdentityRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.domain.vo.Email;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final TokenService tokens;
    private final SocialIdentityRepository socialIdentities;
    private final SocialIdentityVerifier socialIdentityVerifier;

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
        return tokens.issue(users.save(user));
    }

    @Transactional
    public TokenService.TokenPair login(String email, String password) {
        authenticationManager.authenticate(
            UsernamePasswordAuthenticationToken.unauthenticated(email, password));
        User user = users.findByEmail(email)
            .orElseThrow(() -> new IllegalArgumentException("Identifiants invalides"));
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

    private User requireActiveUser(Long userId) {
        return users.findById(userId)
            .filter(User::active)
            .orElseThrow(() -> new BadCredentialsException("Compte inactif ou introuvable"));
    }

    private static String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null || fallback.isBlank() ? null : fallback.trim();
    }
}
