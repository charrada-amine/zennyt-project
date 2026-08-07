package com.zennyt.identity.infrastructure;

import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.model.Role;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rejoue un snapshot idempotent pour initialiser les projections des autres contextes.
 *
 * <p>{@code @Transactional} est <b>indispensable</b> : la lecture du profil candidat
 * traverse une collection paresseuse ({@code ProfileEntity.skills}). Sans session
 * ouverte, un {@code LazyInitializationException} remonte jusqu'au démarrage et
 * <b>empêche l'application de booter</b> dès qu'un seul profil candidat existe en base.
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IdentityAccessSnapshotPublisher implements ApplicationRunner {
    private final UserRepository users;
    private final OnboardingRepository onboarding;
    private final ProfileRepository profiles;
    private final ApplicationEventPublisher events;

    @Override
    public void run(ApplicationArguments args) {
        users.findAll().forEach(user -> {
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
        });
    }
}
