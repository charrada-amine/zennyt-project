package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.domain.model.IdentityVerification;
import com.zennyt.recruitment.domain.repository.IdentityVerificationRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.IdentityVerificationStatus;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/** Contrôleur REST pour les vérifications d'identité anti-fraude. */
@RestController
@RequestMapping("/api/v1/identity-verifications")
public class IdentityVerificationController {

    private final IdentityVerificationRepository repository;
    private final JobOfferRepository jobOffers;

    public IdentityVerificationController(IdentityVerificationRepository repository,
                                          JobOfferRepository jobOffers) {
        this.repository = repository;
        this.jobOffers = jobOffers;
    }

    record RequestVerificationReq(UUID candidateId, UUID jobOfferId) {}
    record VerificationResponse(UUID id, UUID candidateId, IdentityVerificationStatus status, String requestedAt) {
        static VerificationResponse from(IdentityVerification v) {
            return new VerificationResponse(v.id(), v.targetCandidateId(), v.status(), v.requestedAt().toString());
        }
    }

    /** POST — Demander une vérification */
    @PostMapping
    @RecruiterOnly
    public ResponseEntity<VerificationResponse> request(@RequestBody RequestVerificationReq req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var offer = jobOffers.findById(req.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!offer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        IdentityVerification v = IdentityVerification.request(recruiterId, req.candidateId(), req.jobOfferId());
        return ResponseEntity.status(HttpStatus.CREATED).body(VerificationResponse.from(repository.save(v)));
    }

    /** GET /{id} — Statut */
    @GetMapping("/{id}")
    @Authenticated
    public ResponseEntity<VerificationResponse> getById(@PathVariable UUID id, Principal principal) {
        IdentityVerification verification = repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Vérification introuvable"));
        UUID actorId = UUID.fromString(principal.getName());
        if (!verification.requestedByRecruiterId().equals(actorId)
                && !verification.targetCandidateId().equals(actorId)) {
            throw new ForbiddenException("Cette vérification ne vous appartient pas");
        }
        return ResponseEntity.ok(VerificationResponse.from(verification));
    }
}
