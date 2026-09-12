package com.zennyt.identity.application;

import com.zennyt.identity.application.port.EmailPort;
import com.zennyt.identity.application.port.FileStoragePort;
import com.zennyt.identity.application.port.FileStoragePort.ResourceType;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.*;
import com.zennyt.identity.domain.event.ProfileCvUpdatedEvent;
import com.zennyt.identity.domain.event.UserAccessStateChangedEvent;
import com.zennyt.identity.domain.repository.AccountChangeCodeRepository;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserPreferencesRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import com.zennyt.shared.domain.vo.Email;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class IdentityService {
    private static final Logger log = LoggerFactory.getLogger(IdentityService.class);
    private static final String CV_FOLDER = "zennyt/cv";
    private static final String AVATAR_FOLDER = "zennyt/avatars";
    private static final String LOGO_FOLDER = "zennyt/logos";
    private static final int MAX_ACCOUNT_CHANGE_ATTEMPTS = 5;

    private final UserRepository users;
    private final OnboardingRepository onboarding;
    private final ProfileRepository profiles;
    private final UserPreferencesRepository preferences;
    private final AccountChangeCodeRepository accountChangeCodes;
    private final EmailPort email;
    private final FileStoragePort fileStorage;
    private final TokenService tokens;
    private final ApplicationEventPublisher events;

    /** TTL des codes de changement de coordonnée ; injecté par Spring, défaut 10 min. */
    @Value("${identity.account-change.code-ttl:PT10M}")
    private Duration accountChangeCodeTtl = Duration.ofMinutes(10);

    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional(readOnly = true)
    public User currentUser(UUID publicId) {
        return users.findByPublicId(publicId)
            .filter(User::active)
            .orElseThrow(() -> new ForbiddenException("Compte inactif ou introuvable"));
    }

    /** Préférences d'application ; valeurs par défaut si jamais enregistrées. */
    @Transactional(readOnly = true)
    public UserPreferences getPreferences(UUID publicId) {
        User user = currentUser(publicId);
        return preferences.findByUserId(user.id())
            .orElseGet(() -> UserPreferences.defaults(user.id()));
    }

    @Transactional
    public UserPreferences updatePreferences(UUID publicId, boolean notificationsEnabled,
                                             boolean highContrast, int textSizePx) {
        User user = currentUser(publicId);
        UserPreferences current = preferences.findByUserId(user.id())
            .orElseGet(() -> UserPreferences.defaults(user.id()));
        return preferences.save(
            current.with(notificationsEnabled, highContrast, textSizePx, Instant.now()));
    }

    // ── Changement de coordonnées (OTP par e-mail, SMS non intégré) ──────────

    /** Demande un changement d'e-mail : envoie un OTP à la NOUVELLE adresse. */
    @Transactional
    public void requestEmailChange(UUID publicId, String rawNewEmail) {
        User user = currentUser(publicId);
        Email newEmail = parseEmail(rawNewEmail);
        boolean takenByOther = users.findByEmail(newEmail.value())
            .filter(existing -> !existing.id().equals(user.id()))
            .isPresent();
        if (takenByOther) {
            throw new ConflictException("Cette adresse e-mail est déjà utilisée");
        }
        issueAccountChangeCode(user, AccountChangeType.EMAIL, newEmail.value(), newEmail.value());
    }

    /** Valide le code et applique la nouvelle adresse (marquée vérifiée). */
    @Transactional
    public User verifyEmailChange(UUID publicId, String code) {
        User user = currentUser(publicId);
        AccountChangeCode change = consumeAccountChangeCode(user.id(), AccountChangeType.EMAIL, code);
        user.changeEmail(new Email(change.target()));
        User saved = users.save(user);
        publishAccessState(saved);
        return saved;
    }

    /**
     * Demande un changement de téléphone. Le canal SMS n'étant pas intégré, le
     * code est livré par e-mail à l'adresse du compte (provisoire).
     */
    @Transactional
    public void requestPhoneChange(UUID publicId, String newPhoneNumber) {
        User user = currentUser(publicId);
        String target = requirePhone(newPhoneNumber);
        issueAccountChangeCode(user, AccountChangeType.PHONE, target, user.email().value());
    }

    @Transactional
    public User verifyPhoneChange(UUID publicId, String code) {
        User user = currentUser(publicId);
        AccountChangeCode change = consumeAccountChangeCode(user.id(), AccountChangeType.PHONE, code);
        user.changePhoneNumber(change.target());
        User saved = users.save(user);
        publishAccessState(saved);
        return saved;
    }

    private void issueAccountChangeCode(User user, AccountChangeType type, String target,
                                        String deliveryEmail) {
        accountChangeCodes.invalidateAllForUserAndType(user.id(), type);
        String code = generateCode();
        accountChangeCodes.save(AccountChangeCode.issue(user.id(), type, target, hash(code),
            Instant.now().plus(accountChangeCodeTtl)));
        // Un échec d'envoi ne doit pas bloquer la demande : on journalise.
        try {
            email.sendAccountChangeCode(deliveryEmail, user.firstName(), code, target);
        } catch (RuntimeException ex) {
            log.warn("Échec de l'envoi du code de changement ({}) pour l'utilisateur {}", type,
                user.id(), ex);
        }
    }

    private AccountChangeCode consumeAccountChangeCode(Long userId, AccountChangeType type,
                                                       String code) {
        AccountChangeCode change = accountChangeCodes
            .findLatestActiveByUserIdAndType(userId, type)
            .filter(value -> value.usableAt(Instant.now()))
            .orElseThrow(() -> new BadCredentialsException("Code de confirmation invalide ou expiré"));
        if (change.attempts() >= MAX_ACCOUNT_CHANGE_ATTEMPTS) {
            throw new BadCredentialsException("Trop de tentatives, demandez un nouveau code");
        }
        if (!MessageDigest.isEqual(hash(code).getBytes(StandardCharsets.UTF_8),
                change.codeHash().getBytes(StandardCharsets.UTF_8))) {
            accountChangeCodes.save(change.withIncrementedAttempts());
            throw new BadCredentialsException("Code de confirmation invalide");
        }
        return accountChangeCodes.save(change.consume());
    }

    private Email parseEmail(String raw) {
        try {
            return new Email(raw);
        } catch (RuntimeException invalid) {
            throw new IllegalArgumentException("Adresse e-mail invalide");
        }
    }

    private String requirePhone(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Le numéro de téléphone est obligatoire");
        }
        String trimmed = raw.trim();
        if (trimmed.length() > 30) {
            throw new IllegalArgumentException("Le numéro de téléphone est trop long");
        }
        return trimmed;
    }

    private String generateCode() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }

    private String hash(String value) {
        try {
            return java.util.HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 indisponible", ex);
        }
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
