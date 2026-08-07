package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.GetCandidateResumeUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.UUID;

/**
 * Contrôleur REST pour le résumé IA candidat ("Resume AI").
 *
 * <p>Deux routes pour deux publics (P5) : le recruteur lit une analyse factuelle du
 * candidat, le candidat lit la même évaluation formulée à son intention. Deux sections
 * × deux publics = les quatre résumés d'un candidat sur un métier.
 */
@RestController
@RequestMapping("/api/v1")
public class CandidateResumeController {

    private final GetCandidateResumeUseCase getResume;

    public CandidateResumeController(GetCandidateResumeUseCase getResume) {
        this.getResume = getResume;
    }

    record SectionResponse(boolean available, String textFr, String textEn, Instant updatedAt) {
        static SectionResponse from(GetCandidateResumeUseCase.Section section) {
            return new SectionResponse(section.available(), section.textFr(), section.textEn(), section.updatedAt());
        }
    }
    record ResumeResponse(SectionResponse softSkills, SectionResponse hardSkills) {}

    /** GET /api/v1/candidates/{candidateId}/resume?jobOfferId= — Résumé IA (recruteur, offre propriétaire) */
    @GetMapping("/candidates/{candidateId}/resume")
    @RecruiterOnly
    public ResponseEntity<ResumeResponse> getResume(@PathVariable UUID candidateId,
            @RequestParam UUID jobOfferId, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(toResponse(getResume.execute(candidateId, jobOfferId, recruiterId)));
    }

    /**
     * GET /api/v1/candidates/me/resume?jobOfferId= — Résumé IA, version candidat.
     *
     * <p>{@code me} et non un identifiant en chemin : le candidat vient du jeton, ce qui
     * rend structurellement impossible de lire le résumé de quelqu'un d'autre.
     * {@code jobOfferId} est facultatif — il ne sert qu'à désigner le métier de la section
     * hard skills ; sans lui, seule la section soft skills est renseignée.
     */
    @GetMapping("/candidates/me/resume")
    @CandidateOrStudentOnly
    public ResponseEntity<ResumeResponse> getMyResume(
            @RequestParam(required = false) UUID jobOfferId, Principal principal) {
        UUID candidateId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(toResponse(getResume.executeForSelf(candidateId, jobOfferId)));
    }

    private static ResumeResponse toResponse(GetCandidateResumeUseCase.Result result) {
        return new ResumeResponse(
            SectionResponse.from(result.softSkills()), SectionResponse.from(result.hardSkills()));
    }
}
