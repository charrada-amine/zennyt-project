package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.PageResponse;
import com.zennyt.recruitment.application.usecase.GetMatchingDeckUseCase;
import com.zennyt.recruitment.application.usecase.RecordSwipeUseCase;
import com.zennyt.recruitment.application.usecase.UndoSwipeUseCase;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.model.Swipe;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.recruitment.domain.vo.SwipeDirection;
import com.zennyt.recruitment.domain.vo.SwipeSide;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/**
 * Contrôleur REST pour les swipes et decks de matching (contrat squad web §5).
 *
 * <p>Routes imbriquées sous {@code /job-offers} : le côté candidat swipe
 * sur l'offre elle-même, le côté recruteur swipe sur un candidat pour une
 * offre qu'il possède.
 */
@RestController
@RequestMapping("/api/v1")
public class SwipeController {

    private final RecordSwipeUseCase recordSwipeUseCase;
    private final UndoSwipeUseCase undoSwipeUseCase;
    private final GetMatchingDeckUseCase matchingDeckUseCase;
    private final JobOfferRepository jobOfferRepository;
    private final RecruitmentActorRepository actors;

    public SwipeController(RecordSwipeUseCase recordSwipeUseCase, UndoSwipeUseCase undoSwipeUseCase,
                           GetMatchingDeckUseCase matchingDeckUseCase, JobOfferRepository jobOfferRepository,
                           RecruitmentActorRepository actors) {
        this.recordSwipeUseCase = recordSwipeUseCase;
        this.undoSwipeUseCase = undoSwipeUseCase;
        this.matchingDeckUseCase = matchingDeckUseCase;
        this.jobOfferRepository = jobOfferRepository;
        this.actors = actors;
    }

    record SwipeRequest(SwipeDirection direction) {}

    record CandidateMatchPreview(UUID id, UUID jobOfferId, String jobTitle, String companyName) {}
    record CandidateSwipeResponse(UUID swipeId, SwipeDirection direction, boolean matched, CandidateMatchPreview match) {}

    record RecruiterMatchPreview(UUID id, UUID candidateId, String candidateFullName, String candidateAvatarUrl) {}
    record RecruiterSwipeResponse(UUID swipeId, SwipeDirection direction, boolean matched, RecruiterMatchPreview match) {}

    record MatchingDeckOfferResponse(UUID id, String title, String companyName, String city, String country,
                                     com.zennyt.recruitment.domain.vo.ContractType contractType,
                                     com.zennyt.recruitment.domain.vo.WorkplaceType workplaceType,
                                     com.zennyt.recruitment.domain.vo.ExperienceLevel experienceLevel,
                                     boolean recruiterAlreadyInterested) {}

    record MatchingDeckCandidateResponse(UUID id, String fullName, String avatarUrl, String headline,
                                         boolean candidateAlreadyInterested) {}

    /** GET /api/v1/job-offers/matching-deck — Deck d'offres à swiper (candidat). */
    @GetMapping("/job-offers/matching-deck")
    @PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT') and "
        + "@recruitmentActorPolicy.activeWithAnyRole(authentication.name, 'CANDIDATE', 'STUDENT')")
    public ResponseEntity<PageResponse<MatchingDeckOfferResponse>> candidateMatchingDeck(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        var result = matchingDeckUseCase.candidateDeck(candidateId, page, size);
        var items = result.content().stream().map(entry -> {
            JobOffer offer = entry.offer();
            String companyName = actors.findById(offer.recruiterId()).map(a -> a.companyName()).orElse(null);
            return new MatchingDeckOfferResponse(offer.id(), offer.title(), companyName,
                offer.location() != null ? offer.location().city() : null,
                offer.location() != null ? offer.location().country() : null,
                offer.contractType(), offer.workplaceType(), offer.experienceLevel(),
                entry.recruiterAlreadyInterested());
        }).toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, result.totalElements()));
    }

    /** GET /api/v1/job-offers/{jobId}/candidates/matching-deck — Deck de candidats à swiper (recruteur, propriétaire). */
    @GetMapping("/job-offers/{jobId}/candidates/matching-deck")
    @PreAuthorize("hasRole('RECRUITER') and @recruitmentActorPolicy.activeWithRole(authentication.name, 'RECRUITER')")
    public ResponseEntity<PageResponse<MatchingDeckCandidateResponse>> recruiterMatchingDeck(
            @PathVariable UUID jobId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var result = matchingDeckUseCase.recruiterDeck(recruiterId, jobId, page, size);
        var items = result.content().stream()
            .map(entry -> new MatchingDeckCandidateResponse(entry.actor().publicUserId(),
                entry.actor().fullName(), entry.actor().avatarUrl(), null,
                entry.candidateAlreadyInterested()))
            .toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, result.totalElements()));
    }

    /** POST /api/v1/job-offers/{jobId}/swipes — Le candidat swipe sur cette offre. */
    @PostMapping("/job-offers/{jobId}/swipes")
    @PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT') and "
        + "@recruitmentActorPolicy.activeWithAnyRole(authentication.name, 'CANDIDATE', 'STUDENT')")
    public ResponseEntity<CandidateSwipeResponse> candidateSwipe(@PathVariable UUID jobId,
            @RequestBody SwipeRequest req, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        var result = recordSwipeUseCase.execute(candidateId, jobId, candidateId, SwipeSide.CANDIDATE, req.direction());
        return ResponseEntity.status(HttpStatus.CREATED).body(toCandidateResponse(result));
    }

    /** DELETE /api/v1/job-offers/{jobId}/swipes/me — Le candidat annule son swipe sur cette offre. */
    @DeleteMapping("/job-offers/{jobId}/swipes/me")
    @PreAuthorize("hasAnyRole('CANDIDATE', 'STUDENT') and "
        + "@recruitmentActorPolicy.activeWithAnyRole(authentication.name, 'CANDIDATE', 'STUDENT')")
    public ResponseEntity<Void> undoCandidateSwipe(@PathVariable UUID jobId, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        undoSwipeUseCase.execute(candidateId, jobId, candidateId, SwipeSide.CANDIDATE);
        return ResponseEntity.noContent().build();
    }

    /** POST /api/v1/job-offers/{jobId}/candidates/{candidateId}/swipes — Le recruteur swipe sur ce candidat. */
    @PostMapping("/job-offers/{jobId}/candidates/{candidateId}/swipes")
    @PreAuthorize("hasRole('RECRUITER') and @recruitmentActorPolicy.activeWithRole(authentication.name, 'RECRUITER')")
    public ResponseEntity<RecruiterSwipeResponse> recruiterSwipe(@PathVariable UUID jobId,
            @PathVariable UUID candidateId, @RequestBody SwipeRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var result = recordSwipeUseCase.execute(recruiterId, jobId, candidateId, SwipeSide.RECRUITER, req.direction());
        return ResponseEntity.status(HttpStatus.CREATED).body(toRecruiterResponse(result));
    }

    /** DELETE /api/v1/job-offers/{jobId}/candidates/{candidateId}/swipes/me — Le recruteur annule son swipe. */
    @DeleteMapping("/job-offers/{jobId}/candidates/{candidateId}/swipes/me")
    @PreAuthorize("hasRole('RECRUITER') and @recruitmentActorPolicy.activeWithRole(authentication.name, 'RECRUITER')")
    public ResponseEntity<Void> undoRecruiterSwipe(@PathVariable UUID jobId, @PathVariable UUID candidateId,
                                                   Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        undoSwipeUseCase.execute(recruiterId, jobId, candidateId, SwipeSide.RECRUITER);
        return ResponseEntity.noContent().build();
    }

    private CandidateSwipeResponse toCandidateResponse(RecordSwipeUseCase.Result result) {
        Swipe swipe = result.swipe();
        Match match = result.match();
        CandidateMatchPreview preview = null;
        if (match != null) {
            JobOffer offer = jobOfferRepository.findById(match.jobOfferId()).orElse(null);
            String companyName = actors.findById(match.recruiterId()).map(a -> a.companyName()).orElse(null);
            preview = new CandidateMatchPreview(match.id(), match.jobOfferId(),
                offer != null ? offer.title() : null, companyName);
        }
        return new CandidateSwipeResponse(swipe.id(), swipe.direction(), match != null, preview);
    }

    private RecruiterSwipeResponse toRecruiterResponse(RecordSwipeUseCase.Result result) {
        Swipe swipe = result.swipe();
        Match match = result.match();
        RecruiterMatchPreview preview = null;
        if (match != null) {
            var actor = actors.findById(match.candidateId());
            preview = new RecruiterMatchPreview(match.id(), match.candidateId(),
                actor.map(a -> a.fullName()).orElse(null), actor.map(a -> a.avatarUrl()).orElse(null));
        }
        return new RecruiterSwipeResponse(swipe.id(), swipe.direction(), match != null, preview);
    }
}
