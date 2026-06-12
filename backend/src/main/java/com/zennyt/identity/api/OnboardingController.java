package com.zennyt.identity.api;

import com.zennyt.identity.application.IdentityService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import static com.zennyt.identity.api.IdentityDtos.*;

@RestController
@RequestMapping("/api/v1/onboarding")
public class OnboardingController {
    private final IdentityService identity;

    public OnboardingController(IdentityService identity) {
        this.identity = identity;
    }

    @PostMapping("/candidate-student")
    public ResponseEntity<CandidateStudentOnboardingResponse> createCandidateStudent(
        @AuthenticationPrincipal Jwt jwt,
        @Valid @RequestBody CandidateStudentOnboardingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            CandidateStudentOnboardingResponse.from(identity.saveCandidateStudent(subject(jwt),
                request.school(), request.educationLevel(), request.fieldOfWork(),
                request.lastPositionHeld(), request.yearsOfExperience(), request.cvFileUrl(), true)));
    }

    @GetMapping("/candidate-student/me")
    public CandidateStudentOnboardingResponse getCandidateStudent(@AuthenticationPrincipal Jwt jwt) {
        return CandidateStudentOnboardingResponse.from(
            identity.candidateStudentOnboarding(subject(jwt)));
    }

    @PutMapping("/candidate-student/me")
    public CandidateStudentOnboardingResponse updateCandidateStudent(
        @AuthenticationPrincipal Jwt jwt,
        @Valid @RequestBody CandidateStudentOnboardingRequest request) {
        return CandidateStudentOnboardingResponse.from(identity.saveCandidateStudent(subject(jwt),
            request.school(), request.educationLevel(), request.fieldOfWork(),
            request.lastPositionHeld(), request.yearsOfExperience(), request.cvFileUrl(), false));
    }

    @PostMapping("/recruiter")
    public ResponseEntity<RecruiterOnboardingResponse> createRecruiter(
        @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody RecruiterOnboardingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
            RecruiterOnboardingResponse.from(identity.saveRecruiter(subject(jwt),
                request.jobTitle(), request.companyName(), request.companySize(),
                request.companyLogoUrl(), request.fieldOfWork(), request.companyLocation(),
                request.companyRegistrationNumber(), true)));
    }

    @GetMapping("/recruiter/me")
    public RecruiterOnboardingResponse getRecruiter(@AuthenticationPrincipal Jwt jwt) {
        return RecruiterOnboardingResponse.from(identity.recruiterOnboarding(subject(jwt)));
    }

    @PutMapping("/recruiter/me")
    public RecruiterOnboardingResponse updateRecruiter(
        @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody RecruiterOnboardingRequest request) {
        return RecruiterOnboardingResponse.from(identity.saveRecruiter(subject(jwt),
            request.jobTitle(), request.companyName(), request.companySize(),
            request.companyLogoUrl(), request.fieldOfWork(), request.companyLocation(),
            request.companyRegistrationNumber(), false));
    }

    private UUID subject(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
