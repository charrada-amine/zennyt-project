package com.zennyt.identity.api;

import com.zennyt.identity.application.IdentityService;
import com.zennyt.identity.api.security.Authenticated;
import com.zennyt.identity.api.security.CandidateOrStudentOnly;
import com.zennyt.identity.api.security.CurrentUserId;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.model.SkillType;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ProfileController {
    private static final Set<String> ALLOWED_CV_TYPES = Set.of(
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document");

    private final IdentityService identity;

    @PutMapping("/users/me")
    @Authenticated
    public UserResponse updateUser(@CurrentUserId UUID userId,
                                   @Valid @RequestBody UserUpdateRequest request) {
        return UserResponse.from(identity.updateUser(userId, request.firstName(),
            request.lastName(), request.phoneNumber(), request.city(), request.country(),
            request.address(), request.profileImageUrl()));
    }

    @PatchMapping("/users/me/role")
    @Authenticated
    public UserResponse changeRole(@CurrentUserId UUID userId,
                                   @Valid @RequestBody RoleRequest request) {
        return UserResponse.from(identity.changeRole(userId, request.role()));
    }

    @PostMapping("/profiles")
    @CandidateOrStudentOnly
    public ResponseEntity<ProfileResponse> createProfile(@CurrentUserId UUID userId,
                                                         @Valid @RequestBody ProfileRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            ProfileResponse.from(identity.saveProfile(userId, request.toData(), true)));
    }

    @GetMapping("/profiles/me")
    @CandidateOrStudentOnly
    public ProfileResponse getProfile(@CurrentUserId UUID userId) {
        return ProfileResponse.from(identity.currentProfile(userId));
    }

    @PutMapping("/profiles/me")
    @CandidateOrStudentOnly
    public ProfileResponse updateProfile(@CurrentUserId UUID userId,
                                         @Valid @RequestBody ProfileRequest request) {
        return ProfileResponse.from(identity.saveProfile(userId, request.toData(), false));
    }

    @GetMapping("/profiles/{profileId}")
    public ProfileResponse publicProfile(@PathVariable Long profileId) {
        return ProfileResponse.from(identity.publicProfile(profileId));
    }

    @PostMapping(value = "/profiles/me/cv", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @CandidateOrStudentOnly
    public ProfileResponse uploadCv(@CurrentUserId UUID userId,
                                    @RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Le fichier CV est obligatoire");
        }
        if (!ALLOWED_CV_TYPES.contains(file.getContentType())) {
            throw new IllegalArgumentException("Format de CV non supporté (PDF, DOC ou DOCX attendu)");
        }
        try {
            return ProfileResponse.from(identity.uploadCv(userId, file.getBytes(),
                file.getOriginalFilename(), file.getContentType()));
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la lecture du fichier CV", e);
        }
    }

    @DeleteMapping("/profiles/me/cv")
    @CandidateOrStudentOnly
    public ProfileResponse deleteCv(@CurrentUserId UUID userId) {
        return ProfileResponse.from(identity.deleteCv(userId));
    }

    @GetMapping("/profiles/me/skills")
    @CandidateOrStudentOnly
    public List<SkillResponse> skills(@CurrentUserId UUID userId,
                                      @RequestParam(required = false) SkillType type) {
        return identity.currentProfile(userId).skills().stream()
            .filter(skill -> type == null || skill.type() == type)
            .map(SkillResponse::from)
            .toList();
    }

    @PostMapping("/profiles/me/skills")
    @CandidateOrStudentOnly
    public ResponseEntity<SkillResponse> addSkill(@CurrentUserId UUID userId,
                                                  @Valid @RequestBody SkillRequest request) {
        Profile saved = identity.addSkill(userId, request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.skills().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(SkillResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/skills/{id}")
    @CandidateOrStudentOnly
    public SkillResponse updateSkill(@CurrentUserId UUID userId, @PathVariable Long id,
                                     @Valid @RequestBody SkillRequest request) {
        return identity.updateSkill(userId, id, request.toDomain()).skills().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(SkillResponse::from).orElseThrow();
    }

    @DeleteMapping("/profiles/me/skills/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @CandidateOrStudentOnly
    public void deleteSkill(@CurrentUserId UUID userId, @PathVariable Long id) {
        identity.deleteSkill(userId, id);
    }

    @GetMapping("/profiles/me/positions")
    @CandidateOrStudentOnly
    public List<PositionResponse> positions(@CurrentUserId UUID userId) {
        return identity.currentProfile(userId).positions().stream()
            .map(PositionResponse::from).toList();
    }

    @PostMapping("/profiles/me/positions")
    @CandidateOrStudentOnly
    public ResponseEntity<PositionResponse> addPosition(@CurrentUserId UUID userId,
                                                        @Valid @RequestBody PositionRequest request) {
        Profile saved = identity.addPosition(userId, request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.positions().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(PositionResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/positions/{id}")
    @CandidateOrStudentOnly
    public PositionResponse updatePosition(@CurrentUserId UUID userId, @PathVariable Long id,
                                           @Valid @RequestBody PositionRequest request) {
        return identity.updatePosition(userId, id, request.toDomain()).positions().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(PositionResponse::from)
            .orElseThrow();
    }

    @DeleteMapping("/profiles/me/positions/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @CandidateOrStudentOnly
    public void deletePosition(@CurrentUserId UUID userId, @PathVariable Long id) {
        identity.deletePosition(userId, id);
    }

    @GetMapping("/profiles/me/certifications")
    @CandidateOrStudentOnly
    public List<CertificationResponse> certifications(@CurrentUserId UUID userId) {
        return identity.currentProfile(userId).certifications().stream()
            .map(CertificationResponse::from).toList();
    }

    @PostMapping("/profiles/me/certifications")
    @CandidateOrStudentOnly
    public ResponseEntity<CertificationResponse> addCertification(
        @CurrentUserId UUID userId, @Valid @RequestBody CertificationRequest request) {
        Profile saved = identity.addCertification(userId, request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.certifications().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(CertificationResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/certifications/{id}")
    @CandidateOrStudentOnly
    public CertificationResponse updateCertification(
        @CurrentUserId UUID userId, @PathVariable Long id,
        @Valid @RequestBody CertificationRequest request) {
        return identity.updateCertification(userId, id, request.toDomain())
            .certifications().stream().filter(value -> value.id().equals(id)).findFirst()
            .map(CertificationResponse::from).orElseThrow();
    }

    @DeleteMapping("/profiles/me/certifications/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @CandidateOrStudentOnly
    public void deleteCertification(@CurrentUserId UUID userId, @PathVariable Long id) {
        identity.deleteCertification(userId, id);
    }

    @GetMapping("/profiles/me/education")
    @CandidateOrStudentOnly
    public List<EducationResponse> education(@CurrentUserId UUID userId) {
        return identity.currentProfile(userId).education().stream()
            .map(EducationResponse::from).toList();
    }

    @PostMapping("/profiles/me/education")
    @CandidateOrStudentOnly
    public ResponseEntity<EducationResponse> addEducation(
        @CurrentUserId UUID userId, @Valid @RequestBody EducationRequest request) {
        Profile saved = identity.addEducation(userId, request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.education().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(EducationResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/education/{id}")
    @CandidateOrStudentOnly
    public EducationResponse updateEducation(
        @CurrentUserId UUID userId, @PathVariable Long id,
        @Valid @RequestBody EducationRequest request) {
        return identity.updateEducation(userId, id, request.toDomain()).education().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(EducationResponse::from)
            .orElseThrow();
    }

    @DeleteMapping("/profiles/me/education/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @CandidateOrStudentOnly
    public void deleteEducation(@CurrentUserId UUID userId, @PathVariable Long id) {
        identity.deleteEducation(userId, id);
    }
}
