package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.AdminOnly;
import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.ProposeJobPositionUseCase;
import com.zennyt.recruitment.application.usecase.ReviewJobPositionUseCase;
import com.zennyt.recruitment.domain.model.JobPosition;
import com.zennyt.recruitment.domain.repository.JobPositionRepository;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobPositionStatus;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Contrôleur REST pour le référentiel de métiers (job positions) — utilisé
 * par le formulaire de création d'offre : sélection du métier, puis du
 * niveau (libellés dérivés du métier choisi, défauts Junior/Senior/Lead/Manager
 * sinon).
 */
@RestController
@RequestMapping("/api/v1/job-positions")
public class JobPositionController {

    private final JobPositionRepository positions;
    private final ProposeJobPositionUseCase proposeUseCase;
    private final ReviewJobPositionUseCase reviewUseCase;

    public JobPositionController(JobPositionRepository positions,
                                 ProposeJobPositionUseCase proposeUseCase,
                                 ReviewJobPositionUseCase reviewUseCase) {
        this.positions = positions;
        this.proposeUseCase = proposeUseCase;
        this.reviewUseCase = reviewUseCase;
    }

    record JobPositionResponse(UUID id, String name, String sector, JobProfileType profileType,
                               boolean calibrated, JobPositionStatus status,
                               Map<String, String> levelLabels, Instant createdAt,
                               JobProfileType suggestedProfileType) {
        static JobPositionResponse from(JobPosition position) {
            Map<String, String> labels = new LinkedHashMap<>();
            for (ExperienceLevel level : ExperienceLevel.values()) {
                labels.put(level.name(), position.levelLabel(level));
            }
            return new JobPositionResponse(position.id(), position.name(), position.sector(),
                position.profileType(), position.calibrated(), position.status(), labels, position.createdAt(),
                position.suggestedProfileType());
        }
    }

    /** GET /api/v1/job-positions — Référentiel approuvé (sélection du formulaire de création d'offre) */
    @GetMapping
    @Authenticated
    public ResponseEntity<List<JobPositionResponse>> list(@RequestParam(required = false) String sector) {
        return ResponseEntity.ok(positions.findByStatus(JobPositionStatus.APPROVED, sector)
            .stream().map(JobPositionResponse::from).toList());
    }

    /** GET /api/v1/job-positions/pending — File d'attente d'approbation (admin) */
    @GetMapping("/pending")
    @AdminOnly
    public ResponseEntity<List<JobPositionResponse>> pending() {
        return ResponseEntity.ok(positions.findByStatus(JobPositionStatus.PENDING_APPROVAL, null)
            .stream().map(JobPositionResponse::from).toList());
    }

    record ProposeJobPositionRequest(String name, String sector) {}

    /** POST /api/v1/job-positions — Proposer un métier absent du référentiel (recruteur) */
    @PostMapping
    @RecruiterOnly
    public ResponseEntity<JobPositionResponse> propose(@RequestBody ProposeJobPositionRequest req,
                                                       Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobPosition created = proposeUseCase.execute(recruiterId, req.name(), req.sector());
        return ResponseEntity.status(HttpStatus.CREATED).body(JobPositionResponse.from(created));
    }

    record ApproveJobPositionRequest(JobProfileType profileType) {}

    /** PATCH /api/v1/job-positions/{id}/approve — Approuver un métier proposé (admin) */
    @PatchMapping("/{id}/approve")
    @AdminOnly
    public ResponseEntity<JobPositionResponse> approve(@PathVariable UUID id,
                                                       @RequestBody ApproveJobPositionRequest req) {
        JobPosition approved = reviewUseCase.approve(id, req.profileType());
        return ResponseEntity.ok(JobPositionResponse.from(approved));
    }

    /** PATCH /api/v1/job-positions/{id}/reject — Rejeter un métier proposé (admin) */
    @PatchMapping("/{id}/reject")
    @AdminOnly
    public ResponseEntity<JobPositionResponse> reject(@PathVariable UUID id) {
        JobPosition rejected = reviewUseCase.reject(id);
        return ResponseEntity.ok(JobPositionResponse.from(rejected));
    }
}
