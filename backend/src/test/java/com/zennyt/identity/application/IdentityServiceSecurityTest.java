package com.zennyt.identity.application;

import com.zennyt.identity.application.port.FileStoragePort;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class IdentityServiceSecurityTest {
    private final UserRepository users = mock(UserRepository.class);
    private final OnboardingRepository onboarding = mock(OnboardingRepository.class);
    private final ProfileRepository profiles = mock(ProfileRepository.class);
    private final FileStoragePort storage = mock(FileStoragePort.class);
    private final TokenService tokens = mock(TokenService.class);
    private final ApplicationEventPublisher events = mock(ApplicationEventPublisher.class);
    private final IdentityService service = new IdentityService(
        users, onboarding, profiles, storage, tokens, events);

    @Test
    void publicProfileHidesInactiveAccounts() {
        Profile profile = mock(Profile.class);
        User user = mock(User.class);
        when(profile.userId()).thenReturn(42L);
        when(profiles.findById(7L)).thenReturn(Optional.of(profile));
        when(users.findById(42L)).thenReturn(Optional.of(user));
        when(user.active()).thenReturn(false);

        assertThatThrownBy(() -> service.publicProfile(7L))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void cvLifecycleAlwaysUsesRawStorageType() {
        UUID publicId = UUID.randomUUID();
        User user = mock(User.class);
        Profile profile = mock(Profile.class);
        when(users.findByPublicId(publicId)).thenReturn(Optional.of(user));
        when(user.active()).thenReturn(true);
        when(user.role()).thenReturn(Role.CANDIDATE);
        when(user.id()).thenReturn(42L);
        when(profiles.findByUserId(42L)).thenReturn(Optional.of(profile));
        when(profile.cvPublicId()).thenReturn("old-cv");
        when(profiles.save(profile)).thenReturn(profile);
        when(storage.upload(any(), anyString(), anyString(), anyString(), any()))
            .thenReturn(new FileStoragePort.StoredFile("https://example.test/cv.pdf", "new-cv"));

        service.uploadCv(publicId, "%PDF-test".getBytes(), "cv.pdf", "application/pdf");

        verify(storage).upload(any(), eq("cv.pdf"), eq("application/pdf"),
            eq("zennyt/cv"), eq(FileStoragePort.ResourceType.RAW));
        verify(storage).delete("old-cv", FileStoragePort.ResourceType.RAW);

        reset(storage);
        service.deleteCv(publicId);
        verify(storage).delete("old-cv", FileStoragePort.ResourceType.RAW);
    }

    @Test
    void updateUserPersistsGeneratedAvatarUrl() {
        UUID publicId = UUID.randomUUID();
        User user = mock(User.class);
        when(users.findByPublicId(publicId)).thenReturn(Optional.of(user));
        when(user.active()).thenReturn(true);
        when(user.role()).thenReturn(Role.RECRUITER);
        when(user.firstName()).thenReturn("amine");
        when(user.lastName()).thenReturn("manai");
        when(user.profileImageUrl()).thenReturn(
            "https://api.dicebear.com/9.x/avataaars/png?seed=amine");
        when(users.save(user)).thenReturn(user);

        service.updateUser(publicId, "amine", "manai", "24999243", "tunis", "Tunisia",
            null, "https://api.dicebear.com/9.x/avataaars/png?seed=amine");

        verify(user).updateIdentity("amine", "manai", "24999243", "tunis", "Tunisia", null);
        verify(user).updateAvatar(
            "https://api.dicebear.com/9.x/avataaars/png?seed=amine", null);
        verify(users).save(user);
    }

    @Test
    void updateUserKeepsExistingAvatarWhenUrlBlank() {
        UUID publicId = UUID.randomUUID();
        User user = mock(User.class);
        when(users.findByPublicId(publicId)).thenReturn(Optional.of(user));
        when(user.active()).thenReturn(true);
        when(user.role()).thenReturn(Role.RECRUITER);
        when(user.firstName()).thenReturn("amine");
        when(user.lastName()).thenReturn("manai");
        when(user.profileImageUrl()).thenReturn(null);
        when(users.save(user)).thenReturn(user);

        service.updateUser(publicId, "amine", "manai", "24999243", "tunis", "Tunisia",
            null, "  ");

        verify(user).updateIdentity("amine", "manai", "24999243", "tunis", "Tunisia", null);
        verify(user, never()).updateAvatar(any(), any());
        verify(users).save(user);
    }
}
