package com.zennyt.identity.api;

import com.zennyt.identity.application.IdentityService;
import com.zennyt.identity.domain.model.Profile;
import com.zennyt.identity.domain.model.SkillType;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;

@RestController
@RequestMapping("/api/v1")
public class ProfileController {
    private final IdentityService identity;

    public ProfileController(IdentityService identity) {
        this.identity = identity;
    }

    @PutMapping("/users/me")
    public UserResponse updateUser(@AuthenticationPrincipal Jwt jwt,
                                   @Valid @RequestBody UserUpdateRequest request) {
        return UserResponse.from(identity.updateUser(subject(jwt), request.firstName(),
            request.lastName(), request.phoneNumber(), request.city(), request.country(),
            request.address(), request.profileImageUrl()));
    }

    @PatchMapping("/users/me/role")
    public UserResponse changeRole(@AuthenticationPrincipal Jwt jwt,
                                   @Valid @RequestBody RoleRequest request) {
        return UserResponse.from(identity.changeRole(subject(jwt), request.role()));
    }

    @PostMapping("/profiles")
    public ResponseEntity<ProfileResponse> createProfile(@AuthenticationPrincipal Jwt jwt,
                                                         @Valid @RequestBody ProfileRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            ProfileResponse.from(identity.saveProfile(subject(jwt), request.toData(), true)));
    }

    @GetMapping("/profiles/me")
    public ProfileResponse getProfile(@AuthenticationPrincipal Jwt jwt) {
        return ProfileResponse.from(identity.currentProfile(subject(jwt)));
    }

    @PutMapping("/profiles/me")
    public ProfileResponse updateProfile(@AuthenticationPrincipal Jwt jwt,
                                         @Valid @RequestBody ProfileRequest request) {
        return ProfileResponse.from(identity.saveProfile(subject(jwt), request.toData(), false));
    }

    @GetMapping("/profiles/{profileId}")
    public ProfileResponse publicProfile(@PathVariable Long profileId) {
        return ProfileResponse.from(identity.publicProfile(profileId));
    }

    @GetMapping("/profiles/me/skills")
    public List<SkillResponse> skills(@AuthenticationPrincipal Jwt jwt,
                                      @RequestParam(required = false) SkillType type) {
        return identity.currentProfile(subject(jwt)).skills().stream()
            .filter(skill -> type == null || skill.type() == type)
            .map(SkillResponse::from)
            .toList();
    }

    @PostMapping("/profiles/me/skills")
    public ResponseEntity<SkillResponse> addSkill(@AuthenticationPrincipal Jwt jwt,
                                                  @Valid @RequestBody SkillRequest request) {
        Profile saved = identity.addSkill(subject(jwt), request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.skills().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(SkillResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/skills/{id}")
    public SkillResponse updateSkill(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
                                     @Valid @RequestBody SkillRequest request) {
        return identity.updateSkill(subject(jwt), id, request.toDomain()).skills().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(SkillResponse::from).orElseThrow();
    }

    @DeleteMapping("/profiles/me/skills/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteSkill(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        identity.deleteSkill(subject(jwt), id);
    }

    @GetMapping("/profiles/me/positions")
    public List<PositionResponse> positions(@AuthenticationPrincipal Jwt jwt) {
        return identity.currentProfile(subject(jwt)).positions().stream()
            .map(PositionResponse::from).toList();
    }

    @PostMapping("/profiles/me/positions")
    public ResponseEntity<PositionResponse> addPosition(@AuthenticationPrincipal Jwt jwt,
                                                        @Valid @RequestBody PositionRequest request) {
        Profile saved = identity.addPosition(subject(jwt), request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.positions().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(PositionResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/positions/{id}")
    public PositionResponse updatePosition(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
                                           @Valid @RequestBody PositionRequest request) {
        return identity.updatePosition(subject(jwt), id, request.toDomain()).positions().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(PositionResponse::from)
            .orElseThrow();
    }

    @DeleteMapping("/profiles/me/positions/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deletePosition(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        identity.deletePosition(subject(jwt), id);
    }

    @GetMapping("/profiles/me/certifications")
    public List<CertificationResponse> certifications(@AuthenticationPrincipal Jwt jwt) {
        return identity.currentProfile(subject(jwt)).certifications().stream()
            .map(CertificationResponse::from).toList();
    }

    @PostMapping("/profiles/me/certifications")
    public ResponseEntity<CertificationResponse> addCertification(
        @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CertificationRequest request) {
        Profile saved = identity.addCertification(subject(jwt), request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.certifications().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(CertificationResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/certifications/{id}")
    public CertificationResponse updateCertification(
        @AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
        @Valid @RequestBody CertificationRequest request) {
        return identity.updateCertification(subject(jwt), id, request.toDomain())
            .certifications().stream().filter(value -> value.id().equals(id)).findFirst()
            .map(CertificationResponse::from).orElseThrow();
    }

    @DeleteMapping("/profiles/me/certifications/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCertification(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        identity.deleteCertification(subject(jwt), id);
    }

    @GetMapping("/profiles/me/education")
    public List<EducationResponse> education(@AuthenticationPrincipal Jwt jwt) {
        return identity.currentProfile(subject(jwt)).education().stream()
            .map(EducationResponse::from).toList();
    }

    @PostMapping("/profiles/me/education")
    public ResponseEntity<EducationResponse> addEducation(
        @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody EducationRequest request) {
        Profile saved = identity.addEducation(subject(jwt), request.toDomain());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved.education().stream()
            .max(Comparator.comparingLong(value -> value.id() == null ? 0 : value.id()))
            .map(EducationResponse::from).orElseThrow());
    }

    @PutMapping("/profiles/me/education/{id}")
    public EducationResponse updateEducation(
        @AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
        @Valid @RequestBody EducationRequest request) {
        return identity.updateEducation(subject(jwt), id, request.toDomain()).education().stream()
            .filter(value -> value.id().equals(id)).findFirst().map(EducationResponse::from)
            .orElseThrow();
    }

    @DeleteMapping("/profiles/me/education/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEducation(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        identity.deleteEducation(subject(jwt), id);
    }

    private UUID subject(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
