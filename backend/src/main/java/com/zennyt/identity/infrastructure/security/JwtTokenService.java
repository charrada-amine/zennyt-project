package com.zennyt.identity.infrastructure.security;

import com.zennyt.identity.application.port.TokenService;
import com.zennyt.identity.domain.model.RefreshSession;
import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.RefreshSessionRepository;
import com.zennyt.identity.domain.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

@Service
public class JwtTokenService implements TokenService {
    private final JwtEncoder encoder;
    private final RefreshSessionRepository sessions;
    private final UserRepository users;
    private final Duration accessTtl;
    private final Duration refreshTtl;
    private final SecureRandom secureRandom = new SecureRandom();

    public JwtTokenService(JwtEncoder encoder, RefreshSessionRepository sessions,
                           UserRepository users,
                           @Value("${identity.jwt.access-ttl:PT15M}") Duration accessTtl,
                           @Value("${identity.jwt.refresh-ttl:P30D}") Duration refreshTtl) {
        this.encoder = encoder;
        this.sessions = sessions;
        this.users = users;
        this.accessTtl = accessTtl;
        this.refreshTtl = refreshTtl;
    }

    @Override
    public TokenPair issue(User user) {
        Instant now = Instant.now();
        String accessToken = encoder.encode(JwtEncoderParameters.from(
            JwsHeader.with(SignatureAlgorithm.RS256).build(),
            JwtClaimsSet.builder()
                .issuer("zennyt")
                .issuedAt(now)
                .expiresAt(now.plus(accessTtl))
                .subject(user.publicId().toString())
                .claim("uid", user.id())
                .claim("email", user.email().value())
                .claim("role", user.role().name())
                .build()
        )).getTokenValue();

        byte[] bytes = new byte[48];
        secureRandom.nextBytes(bytes);
        String refreshToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        sessions.save(RefreshSession.create(user.id(), hash(refreshToken), now.plus(refreshTtl)));
        return new TokenPair(accessToken, refreshToken, "Bearer", accessTtl.toSeconds());
    }

    @Override
    public TokenPair rotate(String refreshToken) {
        RefreshSession session = sessions.findByTokenHash(hash(refreshToken))
            .orElseThrow(() -> new BadCredentialsException("Refresh token invalide"));
        if (!session.usableAt(Instant.now())) {
            throw new BadCredentialsException("Refresh token expiré ou révoqué");
        }
        sessions.save(session.revoke());
        User user = users.findById(session.userId())
            .filter(User::active)
            .orElseThrow(() -> new BadCredentialsException("Compte inactif ou introuvable"));
        return issue(user);
    }

    @Override
    public void revoke(String refreshToken) {
        sessions.findByTokenHash(hash(refreshToken))
            .filter(session -> session.revokedAt() == null)
            .ifPresent(session -> sessions.save(session.revoke()));
    }

    @Override
    public void revokeAll(Long userId) {
        sessions.revokeAllForUser(userId);
    }

    private String hash(String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Refresh token obligatoire");
        }
        try {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 indisponible", ex);
        }
    }
}
