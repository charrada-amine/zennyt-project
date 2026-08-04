package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.FitScoreDismissalRepository;
import com.zennyt.recruitment.application.usecase.DismissFitScoreUseCase;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
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
    private final RecomputeFitScoresUseCase recomputeFitScores;

    public FitScoreController(FitScoreRepository fitScoreRepository,
                              JobOfferRepository jobOfferRepository,
                              DismissFitScoreUseCase dismissFitScore,
                              FitScoreDismissalRepository dismissals,
                              RecomputeFitScoresUseCase recomputeFitScores) {
        this.fitScoreRepository = fitScoreRepository;
        this.jobOfferRepository = jobOfferRepository;
        this.dismissFitScore = dismissFitScore;
        this.dismissals = dismissals;
        this.recomputeFitScores = recomputeFitScores;
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
        // F04 : le seuil de couverture dépend de la présence d'un QCM sur l'OFFRE,
        // pas de la tentative du candidat (CdC §3.3).
        boolean offerHasAssessment = jobOfferRepository.findById(jobOfferId)
            .map(o -> o.assessmentId() != null).orElse(false);
        return fitScoreRepository.findByCandidateIdAndJobOfferId(candidateId, jobOfferId)
            .map(f -> ResponseEntity.ok(new FitScoreResponse(f.id(), f.candidateId(), f.jobOfferId(),
                f.score(), f.goodFit(), f.softSkillScore(), f.hardSkillScore(),
                f.partialData(offerHasAssessment), f.computedAt().toString())))
            .orElse(ResponseEntity.notFound().build());
    }

    record RecomputeRequest(UUID jobOfferId) {}
    record RecomputeResponse(int pairsWritten) {}

    /**
     * POST /api/v1/fit-scores/recompute — Recalcul synchrone (levier démo,
     * contrat aligné sur le backend Recruitment corrigé). Avec {@code jobOfferId} :
     * tous les candidats projetés contre cette offre ; sans : toutes les offres
     * ACTIVE. Le flux normal reste asynchrone (listeners offre activée / partie jouée).
     */
    @PostMapping("/recompute")
    @RecruiterOnly
    public ResponseEntity<RecomputeResponse> recompute(
            @RequestBody(required = false) RecomputeRequest req) {
        int written = (req != null && req.jobOfferId() != null)
            ? recomputeFitScores.recomputeForOffer(req.jobOfferId())
            : recomputeFitScores.recomputeAllActive();
        return ResponseEntity.ok(new RecomputeResponse(written));
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
                            Integer softSkillScore, Integer hardSkillScore,
                            boolean partialData, String computedAt) {}
}
