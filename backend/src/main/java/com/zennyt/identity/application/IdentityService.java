package com.zennyt.identity.application;

import com.zennyt.identity.application.port.FileStoragePort;
import com.zennyt.identity.application.port.FileStoragePort.ResourceType;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.*;
import com.zennyt.identity.domain.event.ProfileCvUpdatedEvent;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class IdentityService {
    private static final String CV_FOLDER = "zennyt/cv";
    private static final String AVATAR_FOLDER = "zennyt/avatars";
    private static final String LOGO_FOLDER = "zennyt/logos";

    private final UserRepository users;
    private final OnboardingRepository onboarding;
    private final ProfileRepository profiles;
    private final FileStoragePort fileStorage;
    private final TokenService tokens;
    private final ApplicationEventPublisher events;

    @Transactional(readOnly = true)
    public User currentUser(UUID publicId) {
        return users.findByPublicId(publicId)
            .filter(User::active)
            .orElseThrow(() -> new ForbiddenException("Compte inactif ou introuvable"));
    }

    @Transactional
    public User updateUser(UUID publicId, String firstName, String lastName, String phoneNumber,
                           String city, String country, String address, String profileImageUrl) {
        User user = currentUser(publicId);
        user.updateIdentity(firstName, lastName, phoneNumber, city, country, address);
        if (profileImageUrl != null && !profileImageUrl.isBlank()) {
            user.updateAvatar(profileImageUrl, null);
        }
        User saved = users.save(user);
        publishAccessState(saved);
        return saved;
    }

    @Transactional
    public User uploadAvatar(UUID publicId, byte[] content, String filename, String contentType) {
        User user = currentUser(publicId);
        String previousPublicId = user.profileImagePublicId();
        FileStoragePort.StoredFile stored = fileStorage.upload(content, filename, contentType,
            AVATAR_FOLDER, ResourceType.IMAGE);
        user.updateAvatar(stored.url(), stored.publicId());
        User saved = users.save(user);
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.IMAGE);
        }
        publishAccessState(saved);
        return saved;
    }

    @Transactional
    public User deleteAvatar(UUID publicId) {
        User user = currentUser(publicId);
        String previousPublicId = user.profileImagePublicId();
        user.clearAvatar();
        User saved = users.save(user);
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.IMAGE);
        }
        publishAccessState(saved);
        return saved;
    }

    @Transactional
    public void deactivateAccount(UUID publicId) {
        User user = currentUser(publicId);
        user.deactivate();
        User saved = users.save(user);
        tokens.revokeAll(user.id());
        publishAccessState(saved);
    }

    @Transactional
    public void deleteAccount(UUID publicId) {
        User user = currentUser(publicId);
        // Nettoyage best-effort des fichiers Cloudinary avant l'anonymisation.
        safeDelete(user.profileImagePublicId(), ResourceType.IMAGE);
        profiles.findByUserId(user.id())
            .ifPresent(profile -> safeDelete(profile.cvPublicId(), ResourceType.RAW));
        onboarding.findRecruiterByUserId(user.id())
            .ifPresent(recruiter -> safeDelete(recruiter.companyLogoPublicId(), ResourceType.IMAGE));
        user.softDelete();
        User saved = users.save(user);
        tokens.revokeAll(user.id());
        publishAccessState(saved);
    }

    private void safeDelete(String publicId, ResourceType resourceType) {
        if (publicId == null || publicId.isBlank()) {
            return;
        }
        try {
            fileStorage.delete(publicId, resourceType);
        } catch (RuntimeException ignored) {
            // La suppression du compte ne doit pas échouer si le fichier distant est déjà absent.
        }
    }

    @Transactional
    public User changeRole(UUID publicId, Role role) {
        User user = currentUser(publicId);
        user.changeRole(role);
        User saved = users.save(user);
        publishAccessState(saved);
        return saved;
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

    @Transactional
    public CandidateStudentOnboarding saveCandidateStudent(
        UUID publicId, String school, String educationLevel, String fieldOfWork,
        String lastPositionHeld, Integer yearsOfExperience, String cvFileUrl, boolean createOnly) {
        User user = requireProfileRole(publicId);
        CandidateStudentOnboarding existing =
            onboarding.findCandidateStudentByUserId(user.id()).orElse(null);
        if (createOnly && existing != null) {
            throw new ConflictException("L'onboarding candidat/étudiant existe déjà");
        }
        Instant now = Instant.now();
        CandidateStudentOnboarding value = existing == null
            ? CandidateStudentOnboarding.create(user.id(), school, educationLevel, fieldOfWork,
                lastPositionHeld, yearsOfExperience, cvFileUrl)
            : new CandidateStudentOnboarding(existing.id(), user.id(), school, educationLevel,
                fieldOfWork, lastPositionHeld, yearsOfExperience, cvFileUrl,
                existing.createdAt(), now);
        return onboarding.saveCandidateStudent(value);
    }

    @Transactional(readOnly = true)
    public CandidateStudentOnboarding candidateStudentOnboarding(UUID publicId) {
        User user = requireProfileRole(publicId);
        return onboarding.findCandidateStudentByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Onboarding candidat/étudiant introuvable"));
    }

    @Transactional
    public RecruiterOnboarding saveRecruiter(
        UUID publicId, String jobTitle, String companyName, String companySize,
        String fieldOfWork, String companyLocation,
        String companyRegistrationNumber, String aboutMe, boolean createOnly) {
        User user = requireRole(publicId, Role.RECRUITER);
        RecruiterOnboarding existing = onboarding.findRecruiterByUserId(user.id()).orElse(null);
        if (createOnly && existing != null) {
            throw new ConflictException("L'onboarding recruteur existe déjà");
        }
        Instant now = Instant.now();
        // Le logo est géré par des endpoints dédiés : on préserve l'existant lors d'une édition texte.
        RecruiterOnboarding value = existing == null
            ? RecruiterOnboarding.create(user.id(), jobTitle, companyName, companySize,
                null, null, fieldOfWork, companyLocation, companyRegistrationNumber, aboutMe)
            : new RecruiterOnboarding(existing.id(), user.id(), jobTitle, companyName, companySize,
                existing.companyLogoUrl(), existing.companyLogoPublicId(), fieldOfWork,
                companyLocation, companyRegistrationNumber, aboutMe, existing.createdAt(), now);
        return onboarding.saveRecruiter(value);
    }

    @Transactional
    public RecruiterOnboarding uploadCompanyLogo(UUID publicId, byte[] content, String filename,
                                                 String contentType) {
        User user = requireRole(publicId, Role.RECRUITER);
        RecruiterOnboarding existing = onboarding.findRecruiterByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Onboarding recruteur introuvable"));
        String previousPublicId = existing.companyLogoPublicId();
        FileStoragePort.StoredFile stored = fileStorage.upload(content, filename, contentType,
            LOGO_FOLDER, ResourceType.IMAGE);
        RecruiterOnboarding saved = onboarding.saveRecruiter(
            existing.withLogo(stored.url(), stored.publicId()));
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.IMAGE);
        }
        return saved;
    }

    @Transactional
    public RecruiterOnboarding deleteCompanyLogo(UUID publicId) {
        User user = requireRole(publicId, Role.RECRUITER);
        RecruiterOnboarding existing = onboarding.findRecruiterByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Onboarding recruteur introuvable"));
        String previousPublicId = existing.companyLogoPublicId();
        RecruiterOnboarding saved = onboarding.saveRecruiter(existing.withLogo(null, null));
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.IMAGE);
        }
        return saved;
    }

    @Transactional(readOnly = true)
    public RecruiterOnboarding recruiterOnboarding(UUID publicId) {
        User user = requireRole(publicId, Role.RECRUITER);
        return onboarding.findRecruiterByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Onboarding recruteur introuvable"));
    }

    /**
     * Sauvegarde le profil et publie les deux événements dont Recruitment a besoin :
     * {@link ProfileCvUpdatedEvent} pour la projection CV, et l'état d'accès pour la
     * projection {@code RecruitmentActor}.
     *
     * <p>Le second est indispensable : les préférences de recherche d'emploi du candidat
     * (rôle recherché, télétravail, type de contrat, localisation cible, expérience) ne
     * vivent que dans le profil, et {@code CandidateFeedRanker} les lit depuis la
     * projection. Sans cette publication, remplir son profil ne changeait rien au
     * classement « Recommended for you » — la projection ne se mettait à jour qu'au
     * redémarrage suivant, via {@code IdentityAccessSnapshotPublisher}. C'est aussi ce
     * qui déclenche le calcul de l'empreinte du texte « rôle recherché ».
     */
    private Profile saveProfileAndPublish(UUID publicId, Profile profile) {
        Profile saved = profiles.save(profile);
        events.publishEvent(ProfileCvUpdatedEvent.of(publicId, saved));
        publishAccessState(currentUser(publicId));
        return saved;
    }

    @Transactional
    public Profile saveProfile(UUID publicId, ProfileData data, boolean createOnly) {
        User user = requireProfileRole(publicId);
        Profile profile = profiles.findByUserId(user.id()).orElse(null);
        if (createOnly && profile != null) {
            throw new ConflictException("Le profil existe déjà");
        }
        if (profile == null) {
            profile = Profile.create(user.id(), data.currentPosition(), data.lookingFor(),
                data.workplaceType(), data.jobType(), data.targetJobLocation(),
                data.yearsOfExperience(), data.softSkillsScore(), data.aboutMe(),
                data.openInternationally(), data.availabilityType(), data.availabilityDate(),
                data.resumeAiUrl(), data.portfolioUrl());
        } else {
            profile.update(data.currentPosition(), data.lookingFor(), data.workplaceType(),
                data.jobType(), data.targetJobLocation(), data.yearsOfExperience(),
                data.softSkillsScore(), data.aboutMe(), data.openInternationally(),
                data.availabilityType(), data.availabilityDate(), data.resumeAiUrl(),
                data.portfolioUrl());
        }
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional(readOnly = true)
    public Profile currentProfile(UUID publicId) {
        User user = requireProfileRole(publicId);
        return profiles.findByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Profil introuvable"));
    }

    @Transactional(readOnly = true)
    public Profile publicProfile(Long profileId) {
        Profile profile = profiles.findById(profileId)
            .orElseThrow(() -> new NotFoundException("Profil introuvable"));
        users.findById(profile.userId())
            .filter(User::active)
            .orElseThrow(() -> new NotFoundException("Profil introuvable"));
        return profile;
    }

    @Transactional
    public Profile uploadCv(UUID publicId, byte[] content, String filename, String contentType) {
        User user = requireProfileRole(publicId);
        Profile profile = profiles.findByUserId(user.id())
            .orElseGet(() -> profiles.save(Profile.create(user.id(),
                null, null, null, null, null, null, null, null, false, null, null, null, null)));
        String previousPublicId = profile.cvPublicId();
        FileStoragePort.StoredFile stored = fileStorage.upload(content, filename, contentType,
            CV_FOLDER, ResourceType.RAW);
        profile.updateCv(stored.url(), stored.publicId());
        Profile saved = saveProfileAndPublish(publicId, profile);
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.RAW);
        }
        return saved;
    }

    @Transactional
    public Profile deleteCv(UUID publicId) {
        Profile profile = currentProfile(publicId);
        String previousPublicId = profile.cvPublicId();
        profile.clearCv();
        Profile saved = saveProfileAndPublish(publicId, profile);
        if (previousPublicId != null) {
            fileStorage.delete(previousPublicId, ResourceType.RAW);
        }
        return saved;
    }

    @Transactional
    public Profile addSkill(UUID publicId, Skill value) {
        Profile profile = currentProfile(publicId);
        profile.addSkill(value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile updateSkill(UUID publicId, Long id, Skill value) {
        Profile profile = currentProfile(publicId);
        profile.replaceSkill(id, value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public void deleteSkill(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeSkill(id);
        saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile addPosition(UUID publicId, Position value) {
        Profile profile = currentProfile(publicId);
        profile.addPosition(value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile updatePosition(UUID publicId, Long id, Position value) {
        Profile profile = currentProfile(publicId);
        profile.replacePosition(id, value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public void deletePosition(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removePosition(id);
        saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile addCertification(UUID publicId, Certification value) {
        Profile profile = currentProfile(publicId);
        profile.addCertification(value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile updateCertification(UUID publicId, Long id, Certification value) {
        Profile profile = currentProfile(publicId);
        profile.replaceCertification(id, value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public void deleteCertification(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeCertification(id);
        saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile addEducation(UUID publicId, Education value) {
        Profile profile = currentProfile(publicId);
        profile.addEducation(value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public Profile updateEducation(UUID publicId, Long id, Education value) {
        Profile profile = currentProfile(publicId);
        profile.replaceEducation(id, value);
        return saveProfileAndPublish(publicId, profile);
    }

    @Transactional
    public void deleteEducation(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeEducation(id);
        saveProfileAndPublish(publicId, profile);
    }

    private User requireProfileRole(UUID publicId) {
        User user = currentUser(publicId);
        if (!user.role().hasProfessionalProfile()) {
            throw new ForbiddenException("Cette opération est réservée aux candidats et étudiants");
        }
        return user;
    }

    private User requireRole(UUID publicId, Role role) {
        User user = currentUser(publicId);
        if (user.role() != role) {
            throw new ForbiddenException("Cette opération est réservée au rôle " + role);
        }
        return user;
    }

    public record ProfileData(
            String currentPosition, String lookingFor, WorkplaceType workplaceType, JobType jobType,
            String targetJobLocation, Integer yearsOfExperience, Integer softSkillsScore,
            String aboutMe, boolean openInternationally, AvailabilityType availabilityType,
            LocalDate availabilityDate, String resumeAiUrl, String portfolioUrl
    ) {}
}
