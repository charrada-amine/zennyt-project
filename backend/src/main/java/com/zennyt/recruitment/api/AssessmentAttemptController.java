package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.domain.model.*;
import com.zennyt.recruitment.domain.repository.AssessmentAttemptRepository;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
import com.zennyt.recruitment.application.usecase.SubmitAttemptUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Contrôleur REST pour les tentatives d'évaluation. */
@RestController
@RequestMapping("/api/v1/assessment-attempts")
public class AssessmentAttemptController {

    private final AssessmentAttemptRepository attemptRepository;
    private final SubmitAttemptUseCase submitAttemptUseCase;
    private final com.zennyt.recruitment.application.usecase.AssessmentAttemptAccessUseCase accessUseCase;

    public AssessmentAttemptController(AssessmentAttemptRepository attemptRepository,
                                       SubmitAttemptUseCase submitAttemptUseCase,
                                       com.zennyt.recruitment.application.usecase.AssessmentAttemptAccessUseCase accessUseCase) {
        this.attemptRepository = attemptRepository;
        this.submitAttemptUseCase = submitAttemptUseCase;
        this.accessUseCase = accessUseCase;
    }

    record SubmitAttemptRequest(UUID assessmentId, UUID jobOfferId, List<Integer> answers,
                                Boolean consent) {}
    record AttemptResponse(UUID id, UUID assessmentId, UUID candidateId, UUID jobOfferId,
                           UUID applicationId, int score, boolean passed,
                           IntegrityStatus integrityStatus, String submittedAt) {
        static AttemptResponse from(AssessmentAttempt a) {
            return new AttemptResponse(a.id(), a.assessmentId(), a.candidateId(), a.jobOfferId(),
                a.applicationId(), a.score(), a.passed(), a.integrityStatus(), a.submittedAt().toString());
        }
    }

    /** POST /api/v1/assessment-attempts — Soumettre une tentative */
    @PostMapping
    @CandidateOrStudentOnly
    public ResponseEntity<AttemptResponse> submit(@RequestBody SubmitAttemptRequest req, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        if (!Boolean.TRUE.equals(req.consent())) {
            throw new IllegalArgumentException("Le consentement au contrôle d'intégrité est obligatoire");
        }
        var result = submitAttemptUseCase.execute(new SubmitAttemptUseCase.Command(
            candidateId, req.assessmentId(), req.jobOfferId(), req.answers()));
        return ResponseEntity.status(HttpStatus.CREATED).body(AttemptResponse.from(result.attempt()));
    }

    /** GET /api/v1/assessment-attempts/{id} — Résultat d'une tentative */
    @GetMapping("/{id}")
    @Authenticated
    public ResponseEntity<AttemptResponse> getById(@PathVariable UUID id, Principal principal) {
        return ResponseEntity.ok(AttemptResponse.from(
            accessUseCase.getForActor(id, UUID.fromString(principal.getName()))));
    }

    /** GET /api/v1/assessment-attempts?jobOfferId= — Résultats pour une offre (recruteur) */
    @GetMapping
    @RecruiterOnly
    public ResponseEntity<List<AttemptResponse>> forJob(@RequestParam UUID jobOfferId,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        return ResponseEntity.ok(accessUseCase.listForRecruiter(
                jobOfferId, UUID.fromString(principal.getName()), page, size)
            .stream().map(AttemptResponse::from).toList());
    }
}
