package com.zennyt.recruitment.application;

import com.zennyt.recruitment.domain.event.OtpRequestedEvent;
import com.zennyt.recruitment.domain.model.OtpChallenge;
import com.zennyt.recruitment.domain.repository.OtpChallengeRepository;
import com.zennyt.recruitment.domain.vo.OtpPurpose;
import com.zennyt.shared.application.exception.ConflictException;
import com.zennyt.shared.application.exception.NotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class OtpService {
    private final OtpChallengeRepository challenges;
    private final ApplicationEventPublisher events;
    private final Duration ttl;
    private final int maxAttempts;
    private final SecureRandom random = new SecureRandom();

    public OtpService(OtpChallengeRepository challenges, ApplicationEventPublisher events,
                      @Value("${recruitment.otp.ttl:PT10M}") Duration ttl,
                      @Value("${recruitment.otp.max-attempts:5}") int maxAttempts) {
        this.challenges = challenges;
        this.events = events;
        this.ttl = ttl;
        this.maxAttempts = maxAttempts;
    }

    @Transactional
    public void issue(UUID resourceId, UUID recipientUserId, OtpPurpose purpose) {
        Instant now = Instant.now();
        if (challenges.findLatest(resourceId, purpose).filter(v -> v.usableAt(now)).isPresent()) {
            return;
        }
        String code = "%06d".formatted(random.nextInt(1_000_000));
        byte[] saltBytes = new byte[16];
        random.nextBytes(saltBytes);
        String salt = Base64.getUrlEncoder().withoutPadding().encodeToString(saltBytes);
        Instant expiresAt = now.plus(ttl);
        challenges.save(OtpChallenge.issue(resourceId, recipientUserId, purpose,
            salt, hash(salt, code), expiresAt, maxAttempts));
        events.publishEvent(OtpRequestedEvent.of(
            resourceId, recipientUserId, purpose, code, expiresAt));
    }

    @Transactional(noRollbackFor = BadCredentialsException.class)
    public void verify(UUID resourceId, UUID recipientUserId, OtpPurpose purpose, String code) {
        OtpChallenge challenge = challenges.findLatest(resourceId, purpose)
            .orElseThrow(() -> new NotFoundException("Challenge OTP introuvable"));
        if (!challenge.recipientUserId().equals(recipientUserId)) {
            throw new BadCredentialsException("Code OTP invalide");
        }
        final boolean valid;
        try {
            valid = challenge.verify(hash(challenge.salt(), code), Instant.now());
        } catch (IllegalStateException ex) {
            throw new ConflictException(ex.getMessage());
        }
        challenges.save(challenge);
        if (!valid) throw new BadCredentialsException("Code OTP invalide");
    }

    private static String hash(String salt, String code) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(
                (salt + ":" + code).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 indisponible", ex);
        }
    }
}
