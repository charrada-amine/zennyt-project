package com.zennyt.recruitment.api;

import com.zennyt.recruitment.domain.model.*;
import com.zennyt.recruitment.domain.repository.*;
import com.zennyt.recruitment.domain.vo.*;
import com.zennyt.recruitment.infrastructure.security.CallbackSecretVerifier;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Contrôleur REST pour les callbacks tiers (IA, anti-fraude, etc.).
 *
 * <p>Ces endpoints sont appelés par des services externes et protégés par
 * un header secret X-Callback-Secret.
 */
@RestController
@RequestMapping("/api/v1/callbacks")
public class CallbackController {

    private final FitScoreRepository fitScoreRepository;
    private final IdentityVerificationRepository verificationRepository;
    private final CallbackSecretVerifier secretVerifier;

    public CallbackController(FitScoreRepository fitScoreRepository,
                               IdentityVerificationRepository verificationRepository,
                               CallbackSecretVerifier secretVerifier) {
        this.fitScoreRepository = fitScoreRepository;
        this.verificationRepository = verificationRepository;
        this.secretVerifier = secretVerifier;
    }

    record FitScoreCallback(UUID candidateId, UUID jobOfferId, int score) {}
    record IdentityCallback(UUID verificationId, IdentityVerificationStatus status) {}

    /** POST /api/v1/callbacks/fit-score — Score IA calculé */
    @PostMapping("/fit-score")
    public ResponseEntity<Void> fitScore(@RequestBody FitScoreCallback cb,
                                          @RequestHeader(value = "X-Callback-Secret", required = false) String secret) {
        secretVerifier.verify(secret);
        var existing = fitScoreRepository.findByCandidateIdAndJobOfferId(
            cb.candidateId(), cb.jobOfferId());
        if (existing.isPresent()) {
            if (existing.get().score() != cb.score()) {
                throw new ConflictException("Un score différent existe déjà pour cette paire");
            }
            return ResponseEntity.ok().build();
        }
        FitScore score = FitScore.fromCallback(cb.candidateId(), cb.jobOfferId(), cb.score(), Instant.now());
        fitScoreRepository.save(score);
        return ResponseEntity.ok().build();
    }

    /** POST /api/v1/callbacks/identity-verification — Résultat vérification faciale */
    @PostMapping("/identity-verification")
    public ResponseEntity<Void> identity(@RequestBody IdentityCallback cb,
                                          @RequestHeader(value = "X-Callback-Secret", required = false) String secret) {
        secretVerifier.verify(secret);
        IdentityVerification v = verificationRepository.findById(cb.verificationId())
            .orElseThrow(() -> new NotFoundException("Vérification introuvable"));
        if (v.status() == cb.status()) {
            return ResponseEntity.ok().build();
        }
        if (v.status() != IdentityVerificationStatus.PENDING) {
            throw new ConflictException("La vérification a déjà été résolue");
        }
        v.resolve(cb.status());
        verificationRepository.save(v);
        return ResponseEntity.ok().build();
    }
}
