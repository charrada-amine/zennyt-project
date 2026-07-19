package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.dto.MatchResponse;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.domain.model.Match;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/** Contrôleur REST pour les matchs mutuels. */
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

    /** GET /api/v1/candidates/me/matches — Matchs d'un candidat (?candidateId= ou identité authentifiée) */
    @GetMapping("/candidates/me/matches")
    @CandidateOrStudentOnly
    public ResponseEntity<List<MatchResponse>> candidateMatches(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID id = UUID.fromString(principal.getName());
        List<Match> matches = matchRepository.findByCandidateId(id, page, size);
        return ResponseEntity.ok(matches.stream().map(this::enrich).toList());
    }

    /** GET /api/v1/recruiters/me/matches — Matchs d'un recruteur (?recruiterId=), filtrable par offre */
    @GetMapping("/recruiters/me/matches")
    @RecruiterOnly
    public ResponseEntity<List<MatchResponse>> recruiterMatches(
            @RequestParam(required = false) UUID jobOfferId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Principal principal) {
        UUID id = UUID.fromString(principal.getName());
        List<Match> matches = matchRepository.findByRecruiterId(id, jobOfferId, page, size);
        return ResponseEntity.ok(matches.stream().map(this::enrich).toList());
    }

    /** Complète le match avec le nom de l'entreprise (offre) et le nom/avatar du candidat (actor). */
    private MatchResponse enrich(Match m) {
        String companyName = jobOfferRepository.findById(m.jobOfferId())
            .map(o -> o.companyName()).orElse(null);
        var actor = actors.findById(m.candidateId());
        return MatchResponse.from(m, companyName,
            actor.map(a -> a.fullName()).orElse(null),
            actor.map(a -> a.avatarUrl()).orElse(null));
    }
}
