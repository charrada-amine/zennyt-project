package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.application.usecase.DismissFitScoreUseCase;
import com.zennyt.recruitment.api.security.RecruiterOnly;
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
    private final DismissFitScoreUseCase dismissFitScore;
    private final FitScoreDismissalRepository dismissals;

    public FitScoreController(FitScoreRepository fitScoreRepository,
                              JobOfferRepository jobOfferRepository,
                              DismissFitScoreUseCase dismissFitScore,
                              FitScoreDismissalRepository dismissals) {
        this.fitScoreRepository = fitScoreRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.dismissFitScore = dismissFitScore;
        this.dismissals = dismissals;
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
            if (dismissals.isDismissed(actorId, candidateId, jobOfferId)) {
                return ResponseEntity.notFound().build();
            }
        } else if (!actorId.equals(candidateId)) {
            throw new ForbiddenException("Vous ne pouvez consulter que votre propre score");
        }
        return fitScoreRepository.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(f -> ResponseEntity.ok(new FitScoreResponse(f.id(), f.candidateId(), f.jobOfferId(),
                f.score(), f.goodFit(), f.softSkillScore(), f.cvMatchScore(), f.computedAt().toString())))
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping
    @RecruiterOnly
    public ResponseEntity<Void> dismiss(@RequestParam UUID candidateId,
                                        @RequestParam UUID jobOfferId,
                                        Principal principal) {
        dismissFitScore.execute(UUID.fromString(principal.getName()), candidateId, jobOfferId);
        return ResponseEntity.noContent().build();
    }

    record FitScoreResponse(UUID id, UUID candidateId, UUID jobOfferId, int score, boolean goodFit,
                            Integer softSkillScore, Integer cvMatchScore, String computedAt) {}
}
