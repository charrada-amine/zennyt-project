package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.domain.model.*;
import com.zennyt.recruitment.domain.repository.*;
import com.zennyt.recruitment.domain.vo.IntegrityStatus;
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
    private final AssessmentRepository assessmentRepository;
    private final JobOfferRepository jobOfferRepository;
    private final com.zennyt.recruitment.application.usecase.AssessmentAttemptAccessUseCase accessUseCase;

    public AssessmentAttemptController(AssessmentAttemptRepository attemptRepository,
                                       AssessmentRepository assessmentRepository,
                                       JobOfferRepository jobOfferRepository,
                                       com.zennyt.recruitment.application.usecase.AssessmentAttemptAccessUseCase accessUseCase) {
        this.attemptRepository = attemptRepository;
        this.assessmentRepository = assessmentRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.accessUseCase = accessUseCase;
    }

    record SubmitAttemptRequest(UUID assessmentId, UUID jobOfferId, List<Integer> answers) {}
    record AttemptResponse(UUID id, UUID assessmentId, UUID candidateId, UUID jobOfferId,
                           int score, boolean passed, IntegrityStatus integrityStatus, String submittedAt) {
        static AttemptResponse from(AssessmentAttempt a) {
            return new AttemptResponse(a.id(), a.assessmentId(), a.candidateId(), a.jobOfferId(),
                a.score(), a.passed(), a.integrityStatus(), a.submittedAt().toString());
        }
    }

    /** POST /api/v1/assessment-attempts — Soumettre une tentative */
    @PostMapping
    @CandidateOrStudentOnly
    public ResponseEntity<AttemptResponse> submit(@RequestBody SubmitAttemptRequest req, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        if (attemptRepository.existsByCandidateIdAndAssessmentIdAndJobOfferId(candidateId, req.assessmentId(), req.jobOfferId())) {
            throw new IllegalArgumentException("Vous avez déjà passé ce test pour cette offre");
        }
        Assessment assessment = assessmentRepository.findById(req.assessmentId())
            .orElseThrow(() -> new IllegalArgumentException("Évaluation introuvable"));
        var offer = jobOfferRepository.findById(req.jobOfferId())
            .orElseThrow(() -> new IllegalArgumentException("Offre introuvable"));
        if (!req.assessmentId().equals(offer.assessmentId())) {
            throw new IllegalArgumentException("Cette évaluation n'est pas assignée à cette offre");
        }
        AssessmentAttempt attempt = AssessmentAttempt.submit(candidateId, req.assessmentId(),
            req.jobOfferId(), req.answers(), assessment.questions());
        AssessmentAttempt saved = attemptRepository.save(attempt);
        return ResponseEntity.status(HttpStatus.CREATED).body(AttemptResponse.from(saved));
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
