package com.zennyt.identity.application;

import com.zennyt.identity.domain.model.*;
import com.zennyt.identity.domain.repository.OnboardingRepository;
import com.zennyt.identity.domain.repository.ProfileRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class IdentityService {
    private final UserRepository users;
    private final OnboardingRepository onboarding;
    private final ProfileRepository profiles;

    @Transactional(readOnly = true)
    public User currentUser(UUID publicId) {
        return users.findByPublicId(publicId)
            .orElseThrow(() -> new NotFoundException("Utilisateur introuvable"));
    }

    @Transactional
    public User updateUser(UUID publicId, String firstName, String lastName, String phoneNumber,
                           String city, String country, String address, String profileImageUrl) {
        User user = currentUser(publicId);
        user.updateIdentity(firstName, lastName, phoneNumber, city, country, address, profileImageUrl);
        return users.save(user);
    }

    @Transactional
    public User changeRole(UUID publicId, Role role) {
        User user = currentUser(publicId);
        user.changeRole(role);
        return users.save(user);
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
        String companyLogoUrl, String fieldOfWork, String companyLocation,
        String companyRegistrationNumber, boolean createOnly) {
        User user = requireRole(publicId, Role.RECRUITER);
        RecruiterOnboarding existing = onboarding.findRecruiterByUserId(user.id()).orElse(null);
        if (createOnly && existing != null) {
            throw new ConflictException("L'onboarding recruteur existe déjà");
        }
        Instant now = Instant.now();
        RecruiterOnboarding value = existing == null
            ? RecruiterOnboarding.create(user.id(), jobTitle, companyName, companySize,
                companyLogoUrl, fieldOfWork, companyLocation, companyRegistrationNumber)
            : new RecruiterOnboarding(existing.id(), user.id(), jobTitle, companyName, companySize,
                companyLogoUrl, fieldOfWork, companyLocation, companyRegistrationNumber,
                existing.createdAt(), now);
        return onboarding.saveRecruiter(value);
    }

    @Transactional(readOnly = true)
    public RecruiterOnboarding recruiterOnboarding(UUID publicId) {
        User user = requireRole(publicId, Role.RECRUITER);
        return onboarding.findRecruiterByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Onboarding recruteur introuvable"));
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
        return profiles.save(profile);
    }

    @Transactional(readOnly = true)
    public Profile currentProfile(UUID publicId) {
        User user = requireProfileRole(publicId);
        return profiles.findByUserId(user.id())
            .orElseThrow(() -> new NotFoundException("Profil introuvable"));
    }

    @Transactional(readOnly = true)
    public Profile publicProfile(Long profileId) {
        return profiles.findById(profileId)
            .orElseThrow(() -> new NotFoundException("Profil introuvable"));
    }

    @Transactional
    public Profile addSkill(UUID publicId, Skill value) {
        Profile profile = currentProfile(publicId);
        profile.addSkill(value);
        return profiles.save(profile);
    }

    @Transactional
    public Profile updateSkill(UUID publicId, Long id, Skill value) {
        Profile profile = currentProfile(publicId);
        profile.replaceSkill(id, value);
        return profiles.save(profile);
    }

    @Transactional
    public void deleteSkill(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeSkill(id);
        profiles.save(profile);
    }

    @Transactional
    public Profile addPosition(UUID publicId, Position value) {
        Profile profile = currentProfile(publicId);
        profile.addPosition(value);
        return profiles.save(profile);
    }

    @Transactional
    public Profile updatePosition(UUID publicId, Long id, Position value) {
        Profile profile = currentProfile(publicId);
        profile.replacePosition(id, value);
        return profiles.save(profile);
    }

    @Transactional
    public void deletePosition(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removePosition(id);
        profiles.save(profile);
    }

    @Transactional
    public Profile addCertification(UUID publicId, Certification value) {
        Profile profile = currentProfile(publicId);
        profile.addCertification(value);
        return profiles.save(profile);
    }

    @Transactional
    public Profile updateCertification(UUID publicId, Long id, Certification value) {
        Profile profile = currentProfile(publicId);
        profile.replaceCertification(id, value);
        return profiles.save(profile);
    }

    @Transactional
    public void deleteCertification(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeCertification(id);
        profiles.save(profile);
    }

    @Transactional
    public Profile addEducation(UUID publicId, Education value) {
        Profile profile = currentProfile(publicId);
        profile.addEducation(value);
        return profiles.save(profile);
    }

    @Transactional
    public Profile updateEducation(UUID publicId, Long id, Education value) {
        Profile profile = currentProfile(publicId);
        profile.replaceEducation(id, value);
        return profiles.save(profile);
    }

    @Transactional
    public void deleteEducation(UUID publicId, Long id) {
        Profile profile = currentProfile(publicId);
        profile.removeEducation(id);
        profiles.save(profile);
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
