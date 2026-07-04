package com.zennyt.identity.api;

import com.zennyt.identity.application.IdentityService;
import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.*;
import jakarta.validation.constraints.*;
import lombok.experimental.UtilityClass;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@UtilityClass
public final class IdentityDtos {

    public record RegisterRequest(
        @NotBlank @Size(max = 100) String firstName,
        @NotBlank @Size(max = 100) String lastName,
        @NotBlank @Email @Size(max = 150) String email,
        @Size(max = 30) String phoneNumber,
        @NotBlank @Size(min = 8, max = 72) String password,
        @NotNull Role role,
        @Size(max = 100) String city,
        @Size(max = 100) String country,
        @Size(max = 255) String address,
        @AssertTrue boolean termsAccepted
    ) {}

    public record LoginRequest(@NotBlank @Email String email, @NotBlank String password) {}
    public record SocialLoginRequest(
        @NotNull SocialProvider provider,
        @NotBlank String idToken,
        @Size(max = 100) String firstName,
        @Size(max = 100) String lastName,
        Role role,
        boolean termsAccepted
    ) {}
    public record RefreshRequest(@NotBlank String refreshToken) {}
    public record RoleRequest(@NotNull Role role) {}

    public record ChangePasswordRequest(
        @NotBlank String currentPassword,
        @NotBlank @Size(min = 8, max = 72) String newPassword
    ) {}

    public record ForgotPasswordRequest(@NotBlank @Email @Size(max = 150) String email) {}

    public record ResetPasswordRequest(
        @NotBlank @Email @Size(max = 150) String email,
        @NotBlank @Size(min = 4, max = 10) String code,
        @NotBlank @Size(min = 8, max = 72) String newPassword
    ) {}

    public record TokenResponse(String accessToken, String refreshToken, String tokenType,
                                long expiresIn) {
        static TokenResponse from(TokenService.TokenPair pair) {
            return new TokenResponse(pair.accessToken(), pair.refreshToken(), pair.tokenType(),
                pair.expiresIn());
        }
    }

    public record UserUpdateRequest(
        @NotBlank @Size(max = 100) String firstName,
        @NotBlank @Size(max = 100) String lastName,
        @Size(max = 30) String phoneNumber,
        @Size(max = 100) String city,
        @Size(max = 100) String country,
        @Size(max = 255) String address
    ) {}

    public record UserResponse(
        Long id, String firstName, String lastName, String email, String phoneNumber, Role role,
        String city, String country, String address, String profileImageUrl,
        boolean termsAccepted, boolean emailVerified, boolean active,
        Instant createdAt, Instant updatedAt
    ) {
        static UserResponse from(User user) {
            return new UserResponse(user.id(), user.firstName(), user.lastName(),
                user.email().value(), user.phoneNumber(), user.role(), user.city(), user.country(),
                user.address(), user.profileImageUrl(), user.termsAccepted(), user.emailVerified(),
                user.active(), user.createdAt(), user.updatedAt());
        }
    }

    public record CandidateStudentOnboardingRequest(
        @Size(max = 150) String school,
        @Size(max = 150) String educationLevel,
        @Size(max = 150) String fieldOfWork,
        @Size(max = 150) String lastPositionHeld,
        @Min(0) Integer yearsOfExperience,
        @Size(max = 500) String cvFileUrl
    ) {}

    public record CandidateStudentOnboardingResponse(
        Long id, Long userId, String school, String educationLevel, String fieldOfWork,
        String lastPositionHeld, Integer yearsOfExperience, String cvFileUrl,
        Instant createdAt, Instant updatedAt
    ) {
        static CandidateStudentOnboardingResponse from(CandidateStudentOnboarding value) {
            return new CandidateStudentOnboardingResponse(value.id(), value.userId(), value.school(),
                value.educationLevel(), value.fieldOfWork(), value.lastPositionHeld(),
                value.yearsOfExperience(), value.cvFileUrl(), value.createdAt(), value.updatedAt());
        }
    }

    public record RecruiterOnboardingRequest(
        @NotBlank @Size(max = 150) String jobTitle,
        @NotBlank @Size(max = 150) String companyName,
        @NotBlank @Size(max = 100) String companySize,
        @NotBlank @Size(max = 150) String fieldOfWork,
        @NotBlank @Size(max = 150) String companyLocation,
        @NotBlank @Size(max = 100) String companyRegistrationNumber,
        @Size(max = 1000) String aboutMe
    ) {}

    public record RecruiterOnboardingResponse(
        Long id, Long userId, String jobTitle, String companyName, String companySize,
        String companyLogoUrl, String fieldOfWork, String companyLocation,
        String companyRegistrationNumber, String aboutMe, Instant createdAt, Instant updatedAt
    ) {
        static RecruiterOnboardingResponse from(RecruiterOnboarding value) {
            return new RecruiterOnboardingResponse(value.id(), value.userId(), value.jobTitle(),
                value.companyName(), value.companySize(), value.companyLogoUrl(), value.fieldOfWork(),
                value.companyLocation(), value.companyRegistrationNumber(), value.aboutMe(), value.createdAt(),
                value.updatedAt());
        }
    }

    public record ProfileRequest(
        @Size(max = 150) String currentPosition,
        @Size(max = 150) String lookingFor,
        WorkplaceType workplaceType,
        JobType jobType,
        @Size(max = 150) String targetJobLocation,
        @Min(0) Integer yearsOfExperience,
        @Min(0) @Max(100) Integer softSkillsScore,
        String aboutMe,
        boolean openInternationally,
        AvailabilityType availabilityType,
        LocalDate availabilityDate,
        @Size(max = 500) String resumeAiUrl,
        @Size(max = 500) String portfolioUrl
    ) {
        IdentityService.ProfileData toData() {
            return new IdentityService.ProfileData(currentPosition, lookingFor, workplaceType,
                jobType, targetJobLocation, yearsOfExperience, softSkillsScore, aboutMe,
                openInternationally, availabilityType, availabilityDate, resumeAiUrl, portfolioUrl);
        }
    }

    public record ProfileResponse(
        Long id, Long userId, String currentPosition, String lookingFor,
        WorkplaceType workplaceType, JobType jobType, String targetJobLocation,
        Integer yearsOfExperience, Integer softSkillsScore, String aboutMe,
        boolean openInternationally, AvailabilityType availabilityType,
        LocalDate availabilityDate, String resumeAiUrl, String portfolioUrl, String cvUrl,
        Instant createdAt, Instant updatedAt, List<SkillResponse> skills,
        List<PositionResponse> positions, List<CertificationResponse> certifications,
        List<EducationResponse> education
    ) {
        static ProfileResponse from(Profile value) {
            return new ProfileResponse(value.id(), value.userId(), value.currentPosition(),
                value.lookingFor(), value.workplaceType(), value.jobType(),
                value.targetJobLocation(), value.yearsOfExperience(), value.softSkillsScore(),
                value.aboutMe(), value.openInternationally(), value.availabilityType(),
                value.availabilityDate(), value.resumeAiUrl(), value.portfolioUrl(), value.cvUrl(),
                value.createdAt(), value.updatedAt(),
                value.skills().stream().map(SkillResponse::from).toList(),
                value.positions().stream().map(PositionResponse::from).toList(),
                value.certifications().stream().map(CertificationResponse::from).toList(),
                value.education().stream().map(EducationResponse::from).toList());
        }
    }

    public record SkillRequest(
        @NotBlank @Size(max = 100) String name,
        @NotNull SkillType type,
        @Min(1) @Max(5) Integer level
    ) {
        Skill toDomain() { return Skill.create(name, type, level); }
    }

    public record SkillResponse(Long id, String name, SkillType type, Integer level,
                                Instant createdAt, Instant updatedAt) {
        static SkillResponse from(Skill value) {
            return new SkillResponse(value.id(), value.name(), value.type(), value.level(),
                value.createdAt(), value.updatedAt());
        }
    }

    public record PositionRequest(
        @NotBlank @Size(max = 150) String title,
        @Size(max = 150) String companyName,
        @Size(max = 150) String location,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        boolean current
    ) {
        Position toDomain() {
            return Position.create(title, companyName, location, description, startDate, endDate,
                current);
        }
    }

    public record PositionResponse(
        Long id, String title, String companyName, String location, String description,
        LocalDate startDate, LocalDate endDate, boolean current,
        Instant createdAt, Instant updatedAt
    ) {
        static PositionResponse from(Position value) {
            return new PositionResponse(value.id(), value.title(), value.companyName(),
                value.location(), value.description(), value.startDate(), value.endDate(),
                value.current(), value.createdAt(), value.updatedAt());
        }
    }

    public record CertificationRequest(
        @NotBlank @Size(max = 150) String title,
        @Size(max = 150) String issuer,
        LocalDate completionDate,
        @Size(max = 150) String credentialId,
        @Size(max = 500) String credentialUrl
    ) {
        Certification toDomain() {
            return Certification.create(title, issuer, completionDate, credentialId, credentialUrl);
        }
    }

    public record CertificationResponse(
        Long id, String title, String issuer, LocalDate completionDate,
        String credentialId, String credentialUrl, Instant createdAt, Instant updatedAt
    ) {
        static CertificationResponse from(Certification value) {
            return new CertificationResponse(value.id(), value.title(), value.issuer(),
                value.completionDate(), value.credentialId(), value.credentialUrl(),
                value.createdAt(), value.updatedAt());
        }
    }

    public record EducationRequest(
        @NotBlank @Size(max = 150) String degree,
        @Size(max = 150) String school,
        @Size(max = 150) String fieldOfStudy,
        String description,
        LocalDate startDate,
        LocalDate endDate
    ) {
        Education toDomain() {
            return Education.create(degree, school, fieldOfStudy, description, startDate, endDate);
        }
    }

    public record EducationResponse(
        Long id, String degree, String school, String fieldOfStudy, String description,
        LocalDate startDate, LocalDate endDate, Instant createdAt, Instant updatedAt
    ) {
        static EducationResponse from(Education value) {
            return new EducationResponse(value.id(), value.degree(), value.school(),
                value.fieldOfStudy(), value.description(), value.startDate(), value.endDate(),
                value.createdAt(), value.updatedAt());
        }
    }
}
