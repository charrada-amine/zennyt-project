package com.zennyt.identity.api;

import com.zennyt.identity.application.IdentityService;
import com.zennyt.identity.api.security.CandidateOrStudentOnly;
import com.zennyt.identity.api.security.RecruiterOnly;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Set;
import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;
import com.zennyt.identity.api.security.CurrentUserId;

@RestController
@RequestMapping("/api/v1/onboarding")
@RequiredArgsConstructor
public class OnboardingController {
    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of(
        "image/png", "image/jpeg", "image/webp");

    private final IdentityService identity;

    @PostMapping("/candidate-student")
    @CandidateOrStudentOnly
    public ResponseEntity<CandidateStudentOnboardingResponse> createCandidateStudent(
        @CurrentUserId UUID userId,
        @Valid @RequestBody CandidateStudentOnboardingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            CandidateStudentOnboardingResponse.from(identity.saveCandidateStudent(userId,
                request.school(), request.educationLevel(), request.fieldOfWork(),
                request.lastPositionHeld(), request.yearsOfExperience(), request.cvFileUrl(), true)));
    }

    @GetMapping("/candidate-student/me")
    @CandidateOrStudentOnly
    public CandidateStudentOnboardingResponse getCandidateStudent(@CurrentUserId UUID userId) {
        return CandidateStudentOnboardingResponse.from(
            identity.candidateStudentOnboarding(userId));
    }

    @PutMapping("/candidate-student/me")
    @CandidateOrStudentOnly
    public CandidateStudentOnboardingResponse updateCandidateStudent(
        @CurrentUserId UUID userId,
        @Valid @RequestBody CandidateStudentOnboardingRequest request) {
        return CandidateStudentOnboardingResponse.from(identity.saveCandidateStudent(userId,
            request.school(), request.educationLevel(), request.fieldOfWork(),
            request.lastPositionHeld(), request.yearsOfExperience(), request.cvFileUrl(), false));
    }

    @PostMapping("/recruiter")
    @RecruiterOnly
    public ResponseEntity<RecruiterOnboardingResponse> createRecruiter(
        @CurrentUserId UUID userId, @Valid @RequestBody RecruiterOnboardingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            RecruiterOnboardingResponse.from(identity.saveRecruiter(userId,
                request.jobTitle(), request.companyName(), request.companySize(),
                request.fieldOfWork(), request.companyLocation(),
                request.companyRegistrationNumber(), true)));
    }

    @GetMapping("/recruiter/me")
    @RecruiterOnly
    public RecruiterOnboardingResponse getRecruiter(@CurrentUserId UUID userId) {
        return RecruiterOnboardingResponse.from(identity.recruiterOnboarding(userId));
    }

    @PutMapping("/recruiter/me")
    @RecruiterOnly
    public RecruiterOnboardingResponse updateRecruiter(
        @CurrentUserId UUID userId, @Valid @RequestBody RecruiterOnboardingRequest request) {
        return RecruiterOnboardingResponse.from(identity.saveRecruiter(userId,
            request.jobTitle(), request.companyName(), request.companySize(),
            request.fieldOfWork(), request.companyLocation(),
            request.companyRegistrationNumber(), false));
    }

    @PostMapping(value = "/recruiter/me/logo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @RecruiterOnly
    public RecruiterOnboardingResponse uploadCompanyLogo(@CurrentUserId UUID userId,
                                                         @RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Le fichier logo est obligatoire");
        }
        if (!ALLOWED_IMAGE_TYPES.contains(file.getContentType())) {
            throw new IllegalArgumentException("Format d'image non supporté (PNG, JPEG ou WEBP attendu)");
        }
        try {
            return RecruiterOnboardingResponse.from(identity.uploadCompanyLogo(userId,
                file.getBytes(), file.getOriginalFilename(), file.getContentType()));
        } catch (IOException e) {
            throw new UncheckedIOException("Échec de la lecture du fichier logo", e);
        }
    }

    @DeleteMapping("/recruiter/me/logo")
    @RecruiterOnly
    public RecruiterOnboardingResponse deleteCompanyLogo(@CurrentUserId UUID userId) {
        return RecruiterOnboardingResponse.from(identity.deleteCompanyLogo(userId));
    }
}
