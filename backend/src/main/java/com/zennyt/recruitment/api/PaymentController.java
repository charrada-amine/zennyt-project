package com.zennyt.recruitment.api;

import com.zennyt.recruitment.api.security.RecruiterOnly;
import com.zennyt.recruitment.application.OtpService;
import com.zennyt.recruitment.domain.model.VideoConferencePayment;
import com.zennyt.recruitment.domain.repository.VideoConferencePaymentRepository;
import com.zennyt.recruitment.domain.repository.MatchRepository;
import com.zennyt.recruitment.domain.vo.Money;
import com.zennyt.recruitment.domain.vo.PaymentStatus;
import com.zennyt.recruitment.domain.vo.OtpPurpose;
import com.zennyt.shared.application.exception.ForbiddenException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/** Contrôleur REST pour les paiements visioconférence. */
@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final VideoConferencePaymentRepository repository;
    private final MatchRepository matches;
    private final OtpService otp;

    public PaymentController(VideoConferencePaymentRepository repository, MatchRepository matches,
                             OtpService otp) {
        this.repository = repository;
        this.matches = matches;
        this.otp = otp;
    }

    record InitiatePaymentRequest(UUID matchId, String cardLast4, String cardType) {}
    record VerifyOtpRequest(String otpCode) {}
    record PaymentResponse(UUID id, UUID matchId, PaymentStatus status, double total, String currency, boolean otpVerified) {
        static PaymentResponse from(VideoConferencePayment p) {
            return new PaymentResponse(p.id(), p.matchId(), p.status(), p.total().amount(), p.total().currency(), p.otpVerified());
        }
    }

    /** POST — Initier un paiement (9.99 EUR) */
    @PostMapping
    @RecruiterOnly
    public ResponseEntity<PaymentResponse> initiate(@RequestBody InitiatePaymentRequest req, Principal principal) {
        UUID recruiterId = UUID.fromString(principal.getName());
        var match = matches.findById(req.matchId())
            .orElseThrow(() -> new NotFoundException("Match introuvable"));
        if (!match.recruiterId().equals(recruiterId)) {
            throw new ForbiddenException("Ce match ne vous appartient pas");
        }
        Money amount = new Money(9.99, "EUR");
        Money tax = new Money(2.00, "EUR");
        VideoConferencePayment payment = VideoConferencePayment.initiate(
            recruiterId, match.candidateId(), req.matchId(), amount, tax, req.cardLast4(), req.cardType());
        VideoConferencePayment saved = repository.save(payment);
        otp.issue(saved.id(), recruiterId, OtpPurpose.PAYMENT);
        return ResponseEntity.status(HttpStatus.CREATED).body(PaymentResponse.from(saved));
    }

    /** POST /{id}/verify-otp — Confirmer via OTP */
    @PostMapping("/{id}/verify-otp")
    @RecruiterOnly
    public ResponseEntity<PaymentResponse> verifyOtp(@PathVariable UUID id,
            @RequestBody VerifyOtpRequest req, Principal principal) {
        VideoConferencePayment payment = requireOwned(id, principal);
        otp.verify(id, payment.recruiterId(), OtpPurpose.PAYMENT, req.otpCode());
        payment.verifyOtp();
        return ResponseEntity.ok(PaymentResponse.from(repository.save(payment)));
    }

    /** GET /{id} — Détail du paiement */
    @GetMapping("/{id}")
    @RecruiterOnly
    public ResponseEntity<PaymentResponse> getById(@PathVariable UUID id, Principal principal) {
        return ResponseEntity.ok(PaymentResponse.from(requireOwned(id, principal)));
    }

    private VideoConferencePayment requireOwned(UUID id, Principal principal) {
        VideoConferencePayment payment = repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Paiement introuvable"));
        if (!payment.recruiterId().equals(UUID.fromString(principal.getName()))) {
            throw new ForbiddenException("Ce paiement ne vous appartient pas");
        }
        return payment;
    }
}
