package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.*;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.*;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Contrôleur REST pour les offres d'emploi. */
@RestController
@RequestMapping("/api/v1")
public class JobOfferController {

    private final CreateJobOfferUseCase createUseCase;
    private final UpdateJobOfferUseCase updateUseCase;
    private final ChangeJobOfferStatusUseCase changeStatusUseCase;
    private final JobOfferRepository jobOfferRepository;

    public JobOfferController(CreateJobOfferUseCase createUseCase,
                               UpdateJobOfferUseCase updateUseCase,
                               ChangeJobOfferStatusUseCase changeStatusUseCase,
                               JobOfferRepository jobOfferRepository) {
        this.createUseCase = createUseCase;
        this.updateUseCase = updateUseCase;
        this.changeStatusUseCase = changeStatusUseCase;
        this.jobOfferRepository = jobOfferRepository;
    }

    /** POST /api/v1/job-offers — Créer une offre (publiée ACTIVE, postedAt serveur) */
    @PostMapping("/job-offers")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> create(@RequestBody CreateJobOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Location location = new Location(req.city(), req.country(), Boolean.TRUE.equals(req.remote()));
        SalaryRange salary = (req.salaryMin() != null && req.salaryMax() != null && req.currency() != null)
            ? new SalaryRange(req.salaryMin(), req.salaryMax(), req.currency()) : null;
        JobOffer offer = createUseCase.execute(recruiterId, new CreateJobOfferUseCase.Command(
            req.title(), req.companyName(), location, salary,
            req.contractType(), req.workplaceType(), req.experienceLevel(),
            req.fieldOfWork(), req.description(), req.responsibilities(),
            req.minimumQualifications(), req.preferredQualifications(),
            req.whatWeOffer(), req.howToApply(), req.companyInfo(),
            req.assessmentId(), Boolean.TRUE.equals(req.openToInternational())));
        return ResponseEntity.status(HttpStatus.CREATED).body(JobOfferResponse.from(offer));
    }

    /** GET /api/v1/job-offers/{id} — Détail d'une offre */
    @GetMapping("/job-offers/{id}")
    public ResponseEntity<JobOfferResponse> getById(@PathVariable UUID id) {
        return jobOfferRepository.findById(id)
            .filter(offer -> offer.status() == JobOfferStatus.ACTIVE)
            .map(o -> ResponseEntity.ok(JobOfferResponse.from(o)))
            .orElse(ResponseEntity.notFound().build());
    }

    /**
     * GET /api/v1/job-offers — Liste / recherche d'offres.
     *
     * <p>La recherche publique ne retourne que les offres ACTIVE. Les offres d'un
     * recruteur, y compris les brouillons, passent exclusivement par la route `/me`.
     */
    @GetMapping("/job-offers")
    public ResponseEntity<List<JobOfferResponse>> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String contractType,
            @RequestParam(required = false) String experienceLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<JobOffer> offers = jobOfferRepository.search(
            q, location, contractType, null, experienceLevel, null, null, null, page, size);
        return ResponseEntity.ok(offers.stream().map(JobOfferResponse::from).toList());
    }

    /** GET /api/v1/recruiters/me/job-offers — Mes offres (recruteur authentifié) */
    @GetMapping("/recruiters/me/job-offers")
    @RecruiterOnly
    public ResponseEntity<List<JobOfferResponse>> myOffers(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOfferStatus statusEnum = status != null ? JobOfferStatus.valueOf(status) : null;
        List<JobOffer> offers = jobOfferRepository.findByRecruiterId(recruiterId, statusEnum, page, size);
        return ResponseEntity.ok(offers.stream().map(JobOfferResponse::from).toList());
    }

    /**
     * PATCH /api/v1/job-offers/{id} — Mise à jour partielle.
     *
     * <p>Seuls les champs présents dans le corps sont modifiés. Envoyer
     * {@code "assessmentId": null} désassigne l'évaluation ; l'omettre la
     * laisse inchangée. Sert aussi d'endpoint « assigner un test technique ».
     */
    @PatchMapping("/job-offers/{id}")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> update(@PathVariable UUID id,
            @RequestBody UpdateJobOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Optional<UUID> assessmentId = req.assessmentId().isPresent()
            ? Optional.ofNullable(req.assessmentId().get())
            : null; // absent du JSON → inchangé
        JobOffer offer = updateUseCase.execute(id, recruiterId, new UpdateJobOfferUseCase.Command(
            req.title(), req.companyName(), req.city(), req.country(), req.remote(),
            req.salaryMin(), req.salaryMax(), req.currency(),
            req.contractType(), req.workplaceType(), req.experienceLevel(),
            req.fieldOfWork(), req.description(), req.responsibilities(),
            req.minimumQualifications(), req.preferredQualifications(),
            req.whatWeOffer(), req.howToApply(), req.companyInfo(),
            assessmentId, req.openToInternational(), req.status()));
        return ResponseEntity.ok(JobOfferResponse.from(offer));
    }

    /** PATCH /api/v1/job-offers/{id}/status — Changer le statut */
    @PatchMapping("/job-offers/{id}/status")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> changeStatus(@PathVariable UUID id,
            @RequestBody ChangeStatusRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOffer offer = changeStatusUseCase.execute(id, recruiterId, req.status());
        return ResponseEntity.ok(JobOfferResponse.from(offer));
    }

    /** DELETE /api/v1/job-offers/{id} — Supprimer une offre */
    @DeleteMapping("/job-offers/{id}")
    @RecruiterOnly
    public ResponseEntity<Void> delete(@PathVariable UUID id, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOffer offer = jobOfferRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        offer.delete();
        jobOfferRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
