package com.zennyt.identity.application;

import com.zennyt.identity.application.port.FileStoragePort;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.event.ProfileCvUpdatedEvent;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.identity.domain.model.JobType;
import com.zennyt.identity.domain.model.WorkplaceType;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garde-fou : enregistrer un profil candidat doit publier l'état d'accès, pas seulement
 * l'événement CV.
 *
 * <p>Les préférences de recherche d'emploi (rôle recherché, télétravail, type de contrat,
 * localisation cible, expérience) ne vivent que dans le profil Identity, alors que
 * {@code CandidateFeedRanker} les lit dans la projection {@code RecruitmentActor}. Sans
 * cette publication, remplir son profil n'avait <b>aucun effet</b> sur le classement
 * « Recommended for you » : la projection ne se mettait à jour qu'au redémarrage suivant.
 * Le symptôme était silencieux — aucune erreur, juste une personnalisation inerte.
 */
class IdentityServiceProfileProjectionTest {

    private final UserRepository users = mock(UserRepository.class);
    private final OnboardingRepository onboarding = mock(OnboardingRepository.class);
    private final ProfileRepository profiles = mock(ProfileRepository.class);
    private final FileStoragePort storage = mock(FileStoragePort.class);
    private final TokenService tokens = mock(TokenService.class);
    private final ApplicationEventPublisher events = mock(ApplicationEventPublisher.class);
    private final IdentityService service = new IdentityService(
        users, onboarding, profiles, storage, tokens, events);

    @Test
    void enregistrerUnProfilPublieLesPreferencesVersLaProjectionRecruitment() {
        UUID publicId = UUID.randomUUID();
        User user = mock(User.class);
        when(users.findByPublicId(publicId)).thenReturn(Optional.of(user));
        when(user.active()).thenReturn(true);
        when(user.role()).thenReturn(Role.CANDIDATE);
        when(user.id()).thenReturn(42L);
        when(user.publicId()).thenReturn(publicId);
        when(user.firstName()).thenReturn("Aicha");
        when(user.lastName()).thenReturn("Gharbi");
        // Simule un vrai repository : avant l'enregistrement il n'y a pas de profil, après
        // il est relisible. publishAccessState relit le profil (dans la même transaction en
        // production), donc un mock qui renverrait toujours vide masquerait le comportement.
        when(profiles.findByUserId(42L)).thenReturn(Optional.empty());
        when(profiles.save(any())).thenAnswer(invocation -> {
            Profile saved = invocation.getArgument(0);
            when(profiles.findByUserId(42L)).thenReturn(Optional.of(saved));
            return saved;
        });

        service.saveProfile(publicId, new IdentityService.ProfileData(
            "Developpeuse", "Developpeur backend Java", WorkplaceType.REMOTE, JobType.FULL_TIME,
            "Tunis", 3, null, null, false, null, null, null, null), true);

        ArgumentCaptor<Object> captor = ArgumentCaptor.forClass(Object.class);
        verify(events, atLeastOnce()).publishEvent(captor.capture());

        assertThat(captor.getAllValues())
            .as("l'événement CV reste publié")
            .hasAtLeastOneElementOfType(ProfileCvUpdatedEvent.class);

        UserAccessStateChangedEvent accessState = captor.getAllValues().stream()
            .filter(UserAccessStateChangedEvent.class::isInstance)
            .map(UserAccessStateChangedEvent.class::cast)
            .findFirst()
            .orElseThrow(() -> new AssertionError(
                "UserAccessStateChangedEvent non publié : les préférences candidat "
                    + "n'atteindraient jamais la projection Recruitment"));

        assertThat(accessState.publicUserId()).isEqualTo(publicId);
        assertThat(accessState.lookingFor()).isEqualTo("Developpeur backend Java");
        assertThat(accessState.workplaceTypePreference()).isEqualTo("REMOTE");
        assertThat(accessState.jobTypePreference()).isEqualTo("FULL_TIME");
        assertThat(accessState.targetJobLocation()).isEqualTo("Tunis");
        assertThat(accessState.yearsOfExperience()).isEqualTo(3);
    }
}
