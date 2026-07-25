package com.zennyt.identity.application;

import com.zennyt.identity.application.port.EmailPort;
import com.zennyt.identity.application.port.SocialIdentityVerifier;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.*;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.PasswordResetCodeRepository;
import com.zennyt.identity.domain.repository.SocialIdentityRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.domain.vo.Email;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class AuthServiceTest {
    private UserRepository users;
    private PasswordEncoder passwordEncoder;
    private TokenService tokens;
    private SocialIdentityRepository socialIdentities;
    private SocialIdentityVerifier verifier;
    private PasswordResetCodeRepository passwordResetCodes;
    private EmailPort email;
    private AuthService service;

    @BeforeEach
    void setUp() {
        users = mock(UserRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        tokens = mock(TokenService.class);
        socialIdentities = mock(SocialIdentityRepository.class);
        verifier = mock(SocialIdentityVerifier.class);
        passwordResetCodes = mock(PasswordResetCodeRepository.class);
        email = mock(EmailPort.class);
        OnboardingRepository onboarding = mock(OnboardingRepository.class);
        when(onboarding.findRecruiterByUserId(any())).thenReturn(Optional.empty());
        service = new AuthService(users, passwordEncoder, mock(AuthenticationManager.class),
            tokens, socialIdentities, verifier, passwordResetCodes, email, Duration.ofMinutes(10),
            mock(ApplicationEventPublisher.class), onboarding);
    }

    @Test
    void createsAccountFromVerifiedGoogleIdentity() {
        when(verifier.verify(SocialProvider.GOOGLE, "google-token")).thenReturn(
            new SocialIdentityVerifier.VerifiedIdentity(
                "google-sub", "ada@example.com", true, "Ada", "Lovelace",
                "https://example.com/avatar.png"));
        when(socialIdentities.findByProviderAndSubject(SocialProvider.GOOGLE, "google-sub"))
            .thenReturn(Optional.empty());
        when(users.findByEmail("ada@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(any())).thenReturn("social-password-hash");
        when(users.save(any())).thenAnswer(invocation -> persisted(invocation.getArgument(0), 42L));
        TokenService.TokenPair pair = new TokenService.TokenPair("access", "refresh", "Bearer", 900);
        when(tokens.issue(any())).thenReturn(pair);

        TokenService.TokenPair result = service.socialLogin(
            SocialProvider.GOOGLE, "google-token", null, null, Role.CANDIDATE, true);

        assertThat(result).isEqualTo(pair);
        ArgumentCaptor<SocialIdentity> identity = ArgumentCaptor.forClass(SocialIdentity.class);
        verify(socialIdentities).save(identity.capture());
        assertThat(identity.getValue().userId()).isEqualTo(42L);
        assertThat(identity.getValue().providerSubject()).isEqualTo("google-sub");
        ArgumentCaptor<User> user = ArgumentCaptor.forClass(User.class);
        verify(tokens).issue(user.capture());
        assertThat(user.getValue().emailVerified()).isTrue();
        assertThat(user.getValue().profileImageUrl()).isEqualTo("https://example.com/avatar.png");
    }

    @Test
    void repeatAppleLoginUsesProviderSubjectWithoutRequiringEmailClaims() {
        when(verifier.verify(SocialProvider.APPLE, "apple-token")).thenReturn(
            new SocialIdentityVerifier.VerifiedIdentity(
                "apple-sub", null, false, null, null, null));
        when(socialIdentities.findByProviderAndSubject(SocialProvider.APPLE, "apple-sub"))
            .thenReturn(Optional.of(new SocialIdentity(
                5L, 7L, SocialProvider.APPLE, "apple-sub", "ada@example.com",
                Instant.now(), Instant.now())));
        User user = persisted(User.registerSocial(
            "Ada", "Lovelace", new Email("ada@example.com"), "hash",
            Role.STUDENT, null, true), 7L);
        when(users.findById(7L)).thenReturn(Optional.of(user));

        service.socialLogin(SocialProvider.APPLE, "apple-token", null, null, null, false);

        verify(tokens).issue(user);
        verify(users, never()).findByEmail(any());
        verify(socialIdentities, never()).save(any());
    }

    @Test
    void linksVerifiedProviderIdentityToExistingEmailAccount() {
        when(verifier.verify(SocialProvider.GOOGLE, "google-token")).thenReturn(
            new SocialIdentityVerifier.VerifiedIdentity(
                "google-sub", "ada@example.com", true, "Ada", "Lovelace", null));
        when(socialIdentities.findByProviderAndSubject(SocialProvider.GOOGLE, "google-sub"))
            .thenReturn(Optional.empty());
        User localUser = persisted(User.register(
            "Ada", "Lovelace", new Email("ada@example.com"), null, "hash",
            Role.CANDIDATE, null, null, null, true), 9L);
        when(users.findByEmail("ada@example.com")).thenReturn(Optional.of(localUser));
        when(users.save(localUser)).thenReturn(localUser);

        service.socialLogin(SocialProvider.GOOGLE, "google-token", null, null, null, false);

        assertThat(localUser.emailVerified()).isTrue();
        verify(users).save(localUser);
        verify(socialIdentities).save(argThat(identity ->
            identity.userId().equals(9L) && identity.provider() == SocialProvider.GOOGLE));
        verify(tokens).issue(localUser);
    }

    private static User persisted(User user, Long id) {
        return User.rehydrate(id, user.publicId(), user.firstName(), user.lastName(), user.email(),
            user.phoneNumber(), user.passwordHash(), user.role(), user.city(), user.country(),
            user.address(), user.profileImageUrl(), user.profileImagePublicId(),
            user.termsAccepted(), user.emailVerified(), user.active(), user.deletedAt(),
            user.createdAt(), user.updatedAt());
    }
}
