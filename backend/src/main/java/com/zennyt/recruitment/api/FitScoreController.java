package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.shared.application.exception.ForbiddenException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/** Contrôleur REST pour les scores de compatibilité IA. */
@RestController
@RequestMapping("/api/v1/fit-scores")
public class FitScoreController {

    private final FitScoreRepository fitScoreRepository;
    private final JobOfferRepository jobOfferRepository;

    public FitScoreController(FitScoreRepository fitScoreRepository,
                              JobOfferRepository jobOfferRepository) {
        this.fitScoreRepository = fitScoreRepository;
        this.jobOfferRepository = jobOfferRepository;
    }

    /** GET /api/v1/fit-scores?candidateId=&jobOfferId= — Score de compatibilité */
    @GetMapping
    @Authenticated
    public ResponseEntity<?> getFitScore(@RequestParam UUID candidateId, @RequestParam UUID jobOfferId,
                                         Authentication authentication) {
        UUID actorId = UUID.fromString(authentication.getName());
        boolean recruiter = authentication.getAuthorities().stream()
            .anyMatch(authority -> "ROLE_RECRUITER".equals(authority.getAuthority()));
        if (recruiter) {
            boolean ownsOffer = jobOfferRepository.findById(jobOfferId)
                .map(offer -> offer.recruiterId().equals(actorId))
                .orElse(false);
            if (!ownsOffer) {
                throw new ForbiddenException("Cette offre ne vous appartient pas");
            }
        } else if (!actorId.equals(candidateId)) {
            throw new ForbiddenException("Vous ne pouvez consulter que votre propre score");
        }
        return fitScoreRepository.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(f -> ResponseEntity.ok(new FitScoreResponse(f.id(), f.candidateId(), f.jobOfferId(), f.score(), f.computedAt().toString())))
            .orElse(ResponseEntity.notFound().build());
    }

    record FitScoreResponse(UUID id, UUID candidateId, UUID jobOfferId, int score, String computedAt) {}
}
