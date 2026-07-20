package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.*;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.*;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.ApplicationRepository;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Contrôleur REST pour les offres d'emploi. */
@RestController
@RequestMapping("/api/v1")
public class JobOfferController {

    private final CreateJobOfferUseCase createUseCase;
    private final UpdateJobOfferUseCase updateUseCase;
    private final ChangeJobOfferStatusUseCase changeStatusUseCase;
    private final JobOfferRepository jobOfferRepository;
    private final ApplicationRepository applicationRepository;
    private final AssessmentRepository assessmentRepository;
    private final FitScoreRepository fitScoreRepository;
    private final GetSwipeDeckUseCase swipeDeck;
    private final RecruitmentActorRepository actors;

    public JobOfferController(CreateJobOfferUseCase createUseCase,
                               UpdateJobOfferUseCase updateUseCase,
                               ChangeJobOfferStatusUseCase changeStatusUseCase,
                               JobOfferRepository jobOfferRepository,
                               ApplicationRepository applicationRepository,
                               AssessmentRepository assessmentRepository,
                               FitScoreRepository fitScoreRepository,
                               GetSwipeDeckUseCase swipeDeck,
                               RecruitmentActorRepository actors) {
        this.createUseCase = createUseCase;
        this.updateUseCase = updateUseCase;
        this.changeStatusUseCase = changeStatusUseCase;
        this.jobOfferRepository = jobOfferRepository;
        this.applicationRepository = applicationRepository;
        this.assessmentRepository = assessmentRepository;
        this.fitScoreRepository = fitScoreRepository;
        this.swipeDeck = swipeDeck;
        this.actors = actors;
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
            req.assessmentId(), req.jobPositionId(),
            req.passingScore() != null ? req.passingScore() : JobOffer.DEFAULT_PASSING_SCORE,
            Boolean.TRUE.equals(req.openToInternational())));
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(offer, null));
    }

    /** GET /api/v1/job-offers/{id} — Détail d'une offre */
    @GetMapping("/job-offers/{id}")
    public ResponseEntity<JobOfferResponse> getById(@PathVariable UUID id, Authentication authentication) {
        return jobOfferRepository.findById(id)
            .filter(offer -> offer.status() == JobOfferStatus.ACTIVE)
            .map(o -> ResponseEntity.ok(toResponse(o, authentication)))
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
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        List<JobOffer> offers;
        if (isCandidate(authentication) && q == null && location == null
                && contractType == null && experienceLevel == null) {
            offers = swipeDeck.candidateOffers(
                UUID.fromString(authentication.getName()), page, size);
        } else {
            offers = jobOfferRepository.search(
                q, location, contractType, null, experienceLevel, null, null, null, page, size);
        }
        return ResponseEntity.ok(toResponses(offers, authentication));
    }

    /** Deck candidat du recruteur, limité aux projections locales fit-scorées. */
    @GetMapping("/recruiters/me/candidate-feed")
    @RecruiterOnly
    public ResponseEntity<CandidateFeedPageResponse> candidateFeed(
            @RequestParam UUID jobOfferId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        var result = swipeDeck.recruiterCandidates(
            UUID.fromString(principal.getName()), jobOfferId, page, size);
        int safeSize = Math.max(1, size);
        var items = result.content().stream().map(score -> {
            var actor = actors.findById(score.candidateId());
            return new CandidateFeedItemResponse(score.candidateId(),
                actor.map(a -> a.fullName()).orElse(null),
                actor.map(a -> a.avatarUrl()).orElse(null),
                actor.map(a -> a.city()).orElse(null),
                actor.map(a -> a.country()).orElse(null),
                score.score(), score.goodFit(), score.softSkillScore());
        }).toList();
        return ResponseEntity.ok(new CandidateFeedPageResponse(items,
            new PageMetaResponse(Math.max(0, page), safeSize, result.totalElements(),
                (int) Math.ceil(result.totalElements() / (double) safeSize))));
    }

    record CandidateFeedItemResponse(UUID candidateId, String fullName, String avatarUrl,
                                     String city, String country,
                                     int fitScore, boolean goodFit, Integer softSkillsScore) {}
    record PageMetaResponse(int page, int size, long totalElements, int totalPages) {}
    record CandidateFeedPageResponse(List<CandidateFeedItemResponse> content, PageMetaResponse page) {}

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
        return ResponseEntity.ok(toResponses(offers, null));
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
            assessmentId, req.jobPositionId(), req.passingScore(), req.openToInternational(), req.status()));
        return ResponseEntity.ok(toResponse(offer, null));
    }

    /** PATCH /api/v1/job-offers/{id}/status — Changer le statut */
    @PatchMapping("/job-offers/{id}/status")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> changeStatus(@PathVariable UUID id,
            @RequestBody ChangeStatusRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOffer offer = changeStatusUseCase.execute(id, recruiterId, req.status());
        return ResponseEntity.ok(toResponse(offer, null));
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

    private JobOfferResponse toResponse(JobOffer offer, Authentication authentication) {
        return toResponses(List.of(offer), authentication).getFirst();
    }

    private List<JobOfferResponse> toResponses(List<JobOffer> offers, Authentication authentication) {
        if (offers.isEmpty()) return List.of();
        List<UUID> offerIds = offers.stream().map(JobOffer::id).toList();
        Map<UUID, Long> applicantCounts = applicationRepository.countByJobOfferIds(offerIds);
        List<UUID> assessmentIds = offers.stream().map(JobOffer::assessmentId)
            .filter(java.util.Objects::nonNull).distinct().toList();
        Map<UUID, String> shareableLinks = assessmentRepository.findByIdIn(assessmentIds).stream()
            .filter(assessment -> assessment.shareableLink() != null)
            .collect(Collectors.toMap(com.zennyt.recruitment.domain.model.Assessment::id,
                com.zennyt.recruitment.domain.model.Assessment::shareableLink));
        Map<UUID, com.zennyt.recruitment.domain.model.FitScore> scoresByOffer = Map.of();
        if (isCandidate(authentication)) {
            scoresByOffer = fitScoreRepository.findByCandidateIdAndJobOfferIds(
                    UUID.fromString(authentication.getName()), offerIds).stream()
                .collect(Collectors.toMap(com.zennyt.recruitment.domain.model.FitScore::jobOfferId,
                    Function.identity(), (left, right) -> left.computedAt().isAfter(right.computedAt())
                        ? left : right));
        }
        Map<UUID, com.zennyt.recruitment.domain.model.FitScore> finalScoresByOffer = scoresByOffer;
        return offers.stream().map(offer -> {
            String link = offer.assessmentId() == null ? null : shareableLinks.get(offer.assessmentId());
            return JobOfferResponse.from(offer, applicantCounts.getOrDefault(offer.id(), 0L), link,
                finalScoresByOffer.get(offer.id()));
        }).toList();
    }

    private boolean isCandidate(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) return false;
        return authentication.getAuthorities().stream().anyMatch(authority ->
            "ROLE_CANDIDATE".equals(authority.getAuthority())
                || "ROLE_STUDENT".equals(authority.getAuthority()));
    }
}
