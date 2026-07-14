package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.Authenticated;
import com.zennyt.recruitment.api.security.CandidateOrStudentOnly;
import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.OtpService;
import com.zennyt.recruitment.domain.model.*;
import com.zennyt.recruitment.domain.repository.*;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/** Contrôleur REST pour les offres d'opportunité (recruteur → candidat). */
@RestController
@RequestMapping("/api/v1/job-opportunity-offers")
public class JobOpportunityOfferController {

    private final JobOpportunityOfferRepository repository;
    private final JobOfferRepository jobOffers;
    private final OtpService otp;

    public JobOpportunityOfferController(JobOpportunityOfferRepository repository,
                                         JobOfferRepository jobOffers,
                                         OtpService otp) {
        this.repository = repository;
        this.jobOffers = jobOffers;
        this.otp = otp;
    }

    record SendOfferRequest(UUID candidateId, UUID jobOfferId) {}
    record VerifyOtpRequest(String otpCode) {}
    record OfferResponse(UUID id, UUID recruiterId, UUID candidateId, UUID jobOfferId,
                         JobOpportunityStatus status, boolean otpVerified, String sentAt) {
        static OfferResponse from(JobOpportunityOffer o) {
            return new OfferResponse(o.id(), o.recruiterId(), o.candidateId(), o.jobOfferId(),
                o.status(), o.otpVerified(), o.sentAt().toString());
        }
    }

    /** POST — Envoyer une offre d'opportunité */
    @PostMapping
    @RecruiterOnly
    public ResponseEntity<OfferResponse> send(@RequestBody SendOfferRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var jobOffer = jobOffers.findById(req.jobOfferId())
            .orElseThrow(() -> new NotFoundException("Offre introuvable"));
        if (!jobOffer.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Cette offre ne vous appartient pas");
        }
        JobOpportunityOffer offer = JobOpportunityOffer.send(recruiterId, req.candidateId(), req.jobOfferId());
        return ResponseEntity.status(HttpStatus.CREATED).body(OfferResponse.from(repository.save(offer)));
    }

    /** GET /{id} — Détail */
    @GetMapping("/{id}")
    @Authenticated
    public ResponseEntity<OfferResponse> getById(@PathVariable UUID id, Principal principal) {
        return ResponseEntity.ok(OfferResponse.from(requireParticipant(id, principal)));
    }

    /** POST /{id}/confirm — Confirmer (candidat) */
    @PostMapping("/{id}/confirm")
    @CandidateOrStudentOnly
    public ResponseEntity<OfferResponse> confirm(@PathVariable UUID id, Principal principal) {
        JobOpportunityOffer offer = requireCandidate(id, principal);
        offer.confirm();
        JobOpportunityOffer saved = repository.save(offer);
        otp.issue(saved.id(), saved.candidateId(), OtpPurpose.JOB_OPPORTUNITY);
        return ResponseEntity.ok(OfferResponse.from(saved));
    }

    /** POST /{id}/verify-otp — Vérifier OTP */
    @PostMapping("/{id}/verify-otp")
    @CandidateOrStudentOnly
    public ResponseEntity<OfferResponse> verifyOtp(@PathVariable UUID id,
            @RequestBody VerifyOtpRequest req, Principal principal) {
        JobOpportunityOffer offer = requireCandidate(id, principal);
        otp.verify(id, offer.candidateId(), OtpPurpose.JOB_OPPORTUNITY, req.otpCode());
        offer.verifyOtp();
        return ResponseEntity.ok(OfferResponse.from(repository.save(offer)));
    }

    /** POST /{id}/reject — Rejeter (candidat) */
    @PostMapping("/{id}/reject")
    @CandidateOrStudentOnly
    public ResponseEntity<OfferResponse> reject(@PathVariable UUID id, Principal principal) {
        JobOpportunityOffer offer = requireCandidate(id, principal);
        offer.reject();
        return ResponseEntity.ok(OfferResponse.from(repository.save(offer)));
    }

    private JobOpportunityOffer requireParticipant(UUID id, Principal principal) {
        JobOpportunityOffer offer = repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Offre d'opportunité introuvable"));
        UUID actorId = UUID.fromString(principal.getName());
        if (!offer.candidateId().equals(actorId) && !offer.recruiterId().equals(actorId)) {
            throw new ForbiddenException("Cette offre d'opportunité ne vous appartient pas");
        }
        return offer;
    }

    private JobOpportunityOffer requireCandidate(UUID id, Principal principal) {
        JobOpportunityOffer offer = repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Offre d'opportunité introuvable"));
        if (!offer.candidateId().equals(UUID.fromString(principal.getName()))) {
            throw new ForbiddenException("Seul le candidat destinataire peut répondre");
        }
        return offer;
    }
}
