package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.usecase.GetCandidateResumeUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.UUID;

/** Contrôleur REST pour le résumé IA candidat ("Resume AI"). */
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
        var result = getResume.execute(candidateId, jobOfferId, recruiterId);
        return ResponseEntity.ok(new ResumeResponse(
            SectionResponse.from(result.softSkills()), SectionResponse.from(result.hardSkills())));
    }
}
