package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.*;
import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.command.SubmitApplicationCommand;
import com.zennyt.recruitment.application.usecase.ApplicationAccessUseCase;
import com.zennyt.recruitment.application.usecase.ChangeApplicationStatusUseCase;
import com.zennyt.recruitment.application.usecase.SubmitApplicationUseCase;
import com.zennyt.recruitment.application.usecase.GetOfferApplicationsUseCase;
import com.zennyt.recruitment.domain.model.Application;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.vo.ApplicationStatus;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Contrôleur REST pour les candidatures. */
@RestController
@RequestMapping("/api/v1")
public class ApplicationController {

    private final SubmitApplicationUseCase submitUseCase;
    private final ChangeApplicationStatusUseCase changeStatusUseCase;
    private final ApplicationAccessUseCase accessUseCase;
    private final ApplicationRepository applicationRepository;
    private final GetOfferApplicationsUseCase getOfferApplicationsUseCase;

    public ApplicationController(SubmitApplicationUseCase submitUseCase,
                                  ChangeApplicationStatusUseCase changeStatusUseCase,
                                  ApplicationAccessUseCase accessUseCase,
                                  ApplicationRepository applicationRepository,
                                  GetOfferApplicationsUseCase getOfferApplicationsUseCase) {
        this.submitUseCase = submitUseCase;
        this.changeStatusUseCase = changeStatusUseCase;
        this.accessUseCase = accessUseCase;
        this.applicationRepository = applicationRepository;
        this.getOfferApplicationsUseCase = getOfferApplicationsUseCase;
    }

    /** POST /api/v1/applications — Soumettre une candidature */
    @PostMapping("/applications")
    @CandidateOrStudentOnly
    @Deprecated(forRemoval = true)
    public ResponseEntity<ApplicationResponse> submit(@RequestBody SubmitApplicationRequest req, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        Application app = submitUseCase.execute(new SubmitApplicationCommand(candidateId, req.jobOfferId()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApplicationResponse.from(app));
    }

    /** GET /api/v1/candidates/me/applications — Mes candidatures (candidat) */
    @GetMapping("/candidates/me/applications")
    @CandidateOrStudentOnly
    public ResponseEntity<List<ApplicationResponse>> myApplications(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        ApplicationStatus statusEnum = status != null ? ApplicationStatus.valueOf(status) : null;
        List<Application> apps = applicationRepository.findByCandidateId(candidateId, statusEnum, page, size);
        return ResponseEntity.ok(apps.stream().map(ApplicationResponse::from).toList());
    }

    /** GET /api/v1/job-offers/{jobOfferId}/applications — Candidatures pour une offre (recruteur) */
    @GetMapping("/job-offers/{jobOfferId}/applications")
    @RecruiterOnly
    public ResponseEntity<OfferApplicationsResponse> applicationsForJob(
            @PathVariable UUID jobOfferId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        ApplicationStatus statusEnum = status != null ? ApplicationStatus.valueOf(status) : null;
        UUID recruiterId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(OfferApplicationsResponse.from(
            getOfferApplicationsUseCase.execute(jobOfferId, recruiterId, statusEnum, page, size)));
    }

    record BestAttemptResponse(int scorePercent, boolean passed,
                               com.zennyt.recruitment.domain.vo.IntegrityStatus integrityStatus,
                               java.time.Instant submittedAt) {}
    record OfferApplicationResponse(UUID applicationId, UUID candidateId,
                                    ApplicationStatus applicationStatus,
                                    BestAttemptResponse bestAttempt) {}
    record OfferApplicationsResponse(long applicantCount, double successRate,
                                     List<OfferApplicationResponse> applications) {
        static OfferApplicationsResponse from(GetOfferApplicationsUseCase.Result result) {
            return new OfferApplicationsResponse(result.applicantCount(), result.successRate(),
                result.applications().stream().map(row -> new OfferApplicationResponse(
                    row.applicationId(), row.candidateId(), row.applicationStatus(),
                    row.bestAttempt() == null ? null : new BestAttemptResponse(
                        row.bestAttempt().scorePercent(), row.bestAttempt().passed(),
                        row.bestAttempt().integrityStatus(), row.bestAttempt().submittedAt()))).toList());
        }
    }

    /** GET /api/v1/applications/{id} — Détail d'une candidature */
    @GetMapping("/applications/{id}")
    @Authenticated
    public ResponseEntity<ApplicationResponse> getById(@PathVariable UUID id, Principal principal) {
        UUID actorId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(ApplicationResponse.from(accessUseCase.getForActor(id, actorId)));
    }

    /** PATCH /api/v1/applications/{id}/status — Changer le statut (recruteur) */
    @PatchMapping("/applications/{id}/status")
    @RecruiterOnly
    public ResponseEntity<ApplicationResponse> changeStatus(@PathVariable UUID id,
            @RequestBody ChangeApplicationStatusRequest req, Principal principal) {
        Application app = changeStatusUseCase.execute(
            id, UUID.fromString(principal.getName()), req.status());
        return ResponseEntity.ok(ApplicationResponse.from(app));
    }
}
