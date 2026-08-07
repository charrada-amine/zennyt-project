package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.PageResponse;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Contrôleur REST pour les matchs mutuels (contrat squad web §6) — lecture
 * seule, aucune écriture directe : le cycle de vie d'un match est entièrement
 * un effet de bord des actions de swipe (§5.5).
 */
@RestController
@RequestMapping("/api/v1")
public class MatchController {

    private final MatchRepository matchRepository;
    private final JobOfferRepository jobOfferRepository;
    private final RecruitmentActorRepository actors;

    public MatchController(MatchRepository matchRepository, JobOfferRepository jobOfferRepository,
                           RecruitmentActorRepository actors) {
        this.matchRepository = matchRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.actors = actors;
    }

    record MatchedJobOfferSummary(UUID id, String title, String companyName) {}
    record CandidateMatchListItem(UUID id, MatchedJobOfferSummary jobOffer, Instant matchedAt) {}

    record MatchedCandidateSummary(UUID id, String fullName, String avatarUrl) {}
    record RecruiterMatchListItem(UUID id, MatchedCandidateSummary candidate, Instant matchedAt) {}

    /** GET /api/v1/candidates/me/matches — Tous les matchs du candidat connecté. */
    @GetMapping("/candidates/me/matches")
    @CandidateOrStudentOnly
    public ResponseEntity<PageResponse<CandidateMatchListItem>> candidateMatches(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID id = UUID.fromString(principal.getName());
        List<Match> matches = matchRepository.findByCandidateId(id, page, size);
        long totalElements = matchRepository.countByCandidateId(id);
        var items = matches.stream().map(this::toCandidateItem).toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, totalElements));
    }

    /** GET /api/v1/job-offers/{jobId}/matches — Matchs d'une offre (recruteur, propriétaire). */
    @GetMapping("/job-offers/{jobId}/matches")
    @RecruiterOnly
    public ResponseEntity<PageResponse<RecruiterMatchListItem>> matchesForJobOffer(
            @PathVariable UUID jobId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        JobOffer offer = jobOfferRepository.findById(jobId)
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(UUID.fromString(principal.getName()))) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        List<Match> matches = matchRepository.findByJobOfferId(jobId, page, size);
        long totalElements = matchRepository.countByJobOfferId(jobId);
        var items = matches.stream().map(this::toRecruiterItem).toList();
        return ResponseEntity.ok(PageResponse.of(items, page, size, totalElements));
    }

    private CandidateMatchListItem toCandidateItem(Match m) {
        var offer = jobOfferRepository.findById(m.jobOfferId());
        var recruiter = actors.findById(m.recruiterId());
        MatchedJobOfferSummary jobOffer = new MatchedJobOfferSummary(m.jobOfferId(),
            offer.map(o -> o.title()).orElse(null),
            recruiter.map(a -> a.companyName()).orElse(null));
        return new CandidateMatchListItem(m.id(), jobOffer, m.matchedAt());
    }

    private RecruiterMatchListItem toRecruiterItem(Match m) {
        var candidate = actors.findById(m.candidateId());
        MatchedCandidateSummary summary = new MatchedCandidateSummary(m.candidateId(),
            candidate.map(a -> a.fullName()).orElse(null),
            candidate.map(a -> a.avatarUrl()).orElse(null));
        return new RecruiterMatchListItem(m.id(), summary, m.matchedAt());
    }
}
