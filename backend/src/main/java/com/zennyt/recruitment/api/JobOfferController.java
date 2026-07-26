package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.*;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.JobRoleProfileResolver;
import com.zennyt.recruitment.application.usecase.*;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.JobRoleProfile;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SwipeRepository;
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
    private final ReplaceJobOfferUseCase replaceUseCase;
    private final UpdateJobOfferUseCase updateUseCase;
    private final ChangeJobOfferStatusUseCase changeStatusUseCase;
    private final JobOfferRepository jobOfferRepository;
    private final SwipeRepository swipeRepository;
    private final AssessmentRepository assessmentRepository;
    private final FitScoreRepository fitScoreRepository;
    private final GetSwipeDeckUseCase swipeDeck;
    private final RecruitmentActorRepository actors;
    private final JobRoleProfileResolver roleProfileResolver;

    public JobOfferController(CreateJobOfferUseCase createUseCase,
                               ReplaceJobOfferUseCase replaceUseCase,
                               UpdateJobOfferUseCase updateUseCase,
                               ChangeJobOfferStatusUseCase changeStatusUseCase,
                               JobOfferRepository jobOfferRepository,
                               SwipeRepository swipeRepository,
                               AssessmentRepository assessmentRepository,
                               FitScoreRepository fitScoreRepository,
                               GetSwipeDeckUseCase swipeDeck,
                               RecruitmentActorRepository actors,
                               JobRoleProfileResolver roleProfileResolver) {
        this.createUseCase = createUseCase;
        this.replaceUseCase = replaceUseCase;
        this.updateUseCase = updateUseCase;
        this.changeStatusUseCase = changeStatusUseCase;
        this.jobOfferRepository = jobOfferRepository;
        this.swipeRepository = swipeRepository;
        this.assessmentRepository = assessmentRepository;
        this.fitScoreRepository = fitScoreRepository;
        this.swipeDeck = swipeDeck;
        this.actors = actors;
        this.roleProfileResolver = roleProfileResolver;
    }

    /** POST /api/v1/job-offers — Créer une offre (publiée ACTIVE, postedAt serveur) */
    @PostMapping("/job-offers")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> create(@RequestBody CreateJobOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Location location = new Location(req.city(), req.country());
        JobOffer offer = createUseCase.execute(recruiterId, new CreateJobOfferUseCase.Command(
            req.title(), location, req.salaryMin(), req.salaryMax(),
            req.contractType(), req.workplaceType(), req.experienceLevel(),
            req.description(), req.responsibilities(),
            req.minimumQualifications(), req.preferredQualifications(),
            req.whatWeOffer(), req.howToApply(),
            null, req.jobPositionId(),
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
    public ResponseEntity<PageResponse<JobOfferSummaryResponse>> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String contractType,
            @RequestParam(required = false) String experienceLevel,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        List<JobOffer> offers;
        long totalElements;
        if (isCandidate(authentication) && q == null && location == null
                && contractType == null && experienceLevel == null) {
            UUID candidateId = UUID.fromString(authentication.getName());
            offers = swipeDeck.candidateOffers(candidateId, page, size);
            totalElements = jobOfferRepository.countFeedForCandidate(candidateId);
        } else {
            offers = jobOfferRepository.search(
                q, location, contractType, null, experienceLevel, null, null, null, sort, page, size);
            totalElements = jobOfferRepository.countSearch(
                q, location, contractType, null, experienceLevel, null, null, null);
        }
        return ResponseEntity.ok(PageResponse.of(toSummaries(offers, authentication), page, size, totalElements));
    }

    /** Deck candidat du recruteur, limité aux projections locales fit-scorées. */
    @GetMapping("/recruiters/me/candidate-feed")
    @RecruiterOnly
    public ResponseEntity<PageResponse<CandidateFeedItemResponse>> candidateFeed(
            @RequestParam UUID jobOfferId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        var result = swipeDeck.recruiterCandidates(
            UUID.fromString(principal.getName()), jobOfferId, page, size);
        var items = result.content().stream().map(score -> {
            var actor = actors.findById(score.candidateId());
            return new CandidateFeedItemResponse(score.candidateId(),
                actor.map(a -> a.fullName()).orElse(null),
                actor.map(a -> a.avatarUrl()).orElse(null),
                actor.map(a -> a.city()).orElse(null),
                actor.map(a -> a.country()).orElse(null),
                score.score(), score.goodFit(), score.softSkillScore(),
                score.hardSkillScore(), score.partialData());
        }).toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, result.totalElements()));
    }

    record CandidateFeedItemResponse(UUID candidateId, String fullName, String avatarUrl,
                                     String city, String country,
                                     int fitScore, boolean goodFit, Integer softSkillsScore,
                                     Integer hardSkillScore, boolean partialData) {}

    /** GET /api/v1/recruiters/me/job-offers — Mes offres (recruteur authentifié) */
    @GetMapping("/recruiters/me/job-offers")
    @RecruiterOnly
    public ResponseEntity<PageResponse<JobOfferSummaryResponse>> myOffers(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        JobOfferStatus statusEnum = status != null ? JobOfferStatus.valueOf(status) : null;
        List<JobOffer> offers = jobOfferRepository.findByRecruiterId(recruiterId, statusEnum, sort, page, size);
        long totalElements = jobOfferRepository.countByRecruiterId(recruiterId, statusEnum);
        return ResponseEntity.ok(PageResponse.of(toSummaries(offers, null), page, size, totalElements));
    }

    /** PUT /api/v1/job-offers/{id} — Remplacement complet (recruteur propriétaire) */
    @PutMapping("/job-offers/{id}")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> replace(@PathVariable UUID id,
            @RequestBody CreateJobOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Location location = new Location(req.city(), req.country());
        JobOffer offer = replaceUseCase.execute(id, recruiterId, new ReplaceJobOfferUseCase.Command(
            req.title(), location, req.salaryMin(), req.salaryMax(),
            req.contractType(), req.workplaceType(), req.experienceLevel(),
            req.description(), req.responsibilities(),
            req.minimumQualifications(), req.preferredQualifications(),
            req.whatWeOffer(), req.howToApply(),
            req.jobPositionId(), Boolean.TRUE.equals(req.openToInternational())));
        return ResponseEntity.ok(toResponse(offer, null));
    }

    /**
     * PATCH /api/v1/job-offers/{id} — Mise à jour partielle.
     *
     * <p>Seuls {@code status} et/ou {@code assessmentId} sont modifiables ; tout
     * autre champ passe par PUT. Envoyer {@code "assessmentId": null} désassigne
     * l'évaluation ; l'omettre la laisse inchangée.
     */
    @PatchMapping("/job-offers/{id}")
    @RecruiterOnly
    public ResponseEntity<JobOfferResponse> update(@PathVariable UUID id,
            @RequestBody UpdateJobOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        Optional<UUID> assessmentId = req.assessmentId().isPresent()
            ? Optional.ofNullable(req.assessmentId().get())
            : null; // absent du JSON → inchangé
        JobOffer offer = updateUseCase.execute(id, recruiterId,
            new UpdateJobOfferUseCase.Command(assessmentId, req.status()));
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
        Map<UUID, Long> applicantCounts = swipeRepository.countRightByJobOfferIds(List.of(offer.id()));
        String link = shareableLink(offer);
        var fitScore = fitScore(offer, authentication);
        var recruiter = actors.findById(offer.recruiterId());
        return JobOfferResponse.from(offer, applicantCounts.getOrDefault(offer.id(), 0L), link, fitScore,
            recruiter.map(a -> a.companyName()).orElse(null), recruiter.map(a -> a.companyInfo()).orElse(null),
            hardSkillsAlert(offer));
    }

    /**
     * Alerte « hard skills manquant » (CdC Fit Score v3 §6) — purement
     * informationnelle, jamais utilisée dans le calcul du Fit Score. NONE si
     * un QCM est déjà attaché, ou si l'offre n'est pas encore reliée au
     * référentiel de métiers (pas de base pour dériver une alerte).
     */
    private HardSkillsAlertLevel hardSkillsAlert(JobOffer offer) {
        if (offer.assessmentId() != null) return HardSkillsAlertLevel.NONE;
        JobRoleProfile roleProfile = roleProfileResolver.resolve(offer);
        return roleProfile != null ? roleProfile.hardSkillsAlert() : HardSkillsAlertLevel.NONE;
    }

    private String shareableLink(JobOffer offer) {
        if (offer.assessmentId() == null) return null;
        return assessmentRepository.findByIdIn(List.of(offer.assessmentId())).stream()
            .findFirst().map(com.zennyt.recruitment.domain.model.Assessment::shareableLink).orElse(null);
    }

    private com.zennyt.recruitment.domain.model.FitScore fitScore(JobOffer offer, Authentication authentication) {
        if (!isCandidate(authentication)) return null;
        return fitScoreRepository.findByCandidateIdAndJobOfferIds(
                UUID.fromString(authentication.getName()), List.of(offer.id())).stream()
            .max(java.util.Comparator.comparing(com.zennyt.recruitment.domain.model.FitScore::computedAt))
            .orElse(null);
    }

    private List<JobOfferSummaryResponse> toSummaries(List<JobOffer> offers, Authentication authentication) {
        if (offers.isEmpty()) return List.of();
        List<UUID> offerIds = offers.stream().map(JobOffer::id).toList();
        Map<UUID, Long> applicantCounts = swipeRepository.countRightByJobOfferIds(offerIds);
        Map<UUID, com.zennyt.recruitment.domain.model.FitScore> scoresByOffer = fitScoresByOffer(offerIds, authentication);
        return offers.stream().map(offer -> {
            String companyName = actors.findById(offer.recruiterId()).map(a -> a.companyName()).orElse(null);
            return JobOfferSummaryResponse.from(offer, companyName,
                applicantCounts.getOrDefault(offer.id(), 0L), scoresByOffer.get(offer.id()));
        }).toList();
    }

    private Map<UUID, com.zennyt.recruitment.domain.model.FitScore> fitScoresByOffer(
            List<UUID> offerIds, Authentication authentication) {
        if (!isCandidate(authentication)) return Map.of();
        return fitScoreRepository.findByCandidateIdAndJobOfferIds(
                UUID.fromString(authentication.getName()), offerIds).stream()
            .collect(Collectors.toMap(com.zennyt.recruitment.domain.model.FitScore::jobOfferId,
                Function.identity(), (left, right) -> left.computedAt().isAfter(right.computedAt())
                    ? left : right));
    }

    private boolean isCandidate(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) return false;
        return authentication.getAuthorities().stream().anyMatch(authority ->
            "ROLE_CANDIDATE".equals(authority.getAuthority())
                || "ROLE_STUDENT".equals(authority.getAuthority()));
    }
}
