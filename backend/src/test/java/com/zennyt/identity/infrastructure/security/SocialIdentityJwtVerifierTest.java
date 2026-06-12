package com.zennyt.identity.infrastructure.security;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.sun.net.httpserver.HttpServer;
import com.zennyt.identity.application.port.SocialIdentityVerifier;
import com.zennyt.identity.domain.model.SocialProvider;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.BadCredentialsException;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SocialIdentityJwtVerifierTest {
    @Test
    void parsesCommaSeparatedClientIds() {
        assertThat(SocialIdentityJwtVerifier.parseClientIds(
            "web-client, android-client,web-client"))
            .containsExactlyInAnyOrder("web-client", "android-client");
    }

    @Test
    void emptyClientIdsDisableProvider() {
        assertThat(SocialIdentityJwtVerifier.parseClientIds("  ")).isEmpty();
    }

    @Test
    void verifiesGoogleAndAppleSignaturesIssuersAndAudiences() throws Exception {
        RSAKey key = new RSAKeyGenerator(2048).keyID("test-key").generate();
        HttpServer server = jwkServer(key);
        try {
            String jwkSetUri = "http://localhost:" + server.getAddress().getPort() + "/keys";
            SocialIdentityJwtVerifier verifier = new SocialIdentityJwtVerifier(
                "https://accounts.google.com", jwkSetUri, "google-client",
                "https://appleid.apple.com", jwkSetUri, "apple-client");

            SocialIdentityVerifier.VerifiedIdentity google = verifier.verify(
                SocialProvider.GOOGLE,
                token(key, "https://accounts.google.com", "google-client", true));
            SocialIdentityVerifier.VerifiedIdentity apple = verifier.verify(
                SocialProvider.APPLE,
                token(key, "https://appleid.apple.com", "apple-client", "true"));

            assertThat(google.subject()).isEqualTo("provider-subject");
            assertThat(google.emailVerified()).isTrue();
            assertThat(apple.emailVerified()).isTrue();
            assertThatThrownBy(() -> verifier.verify(
                SocialProvider.GOOGLE,
                token(key, "https://accounts.google.com", "wrong-client", true)))
                .isInstanceOf(BadCredentialsException.class);
        } finally {
            server.stop(0);
        }
    }

    private static HttpServer jwkServer(RSAKey key) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        byte[] response = new JWKSet(key.toPublicJWK()).toString().getBytes(StandardCharsets.UTF_8);
        server.createContext("/keys", exchange -> {
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        return server;
    }

    private static String token(RSAKey key, String issuer, String audience,
                                Object emailVerified) throws Exception {
        Instant now = Instant.now();
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
            .issuer(issuer)
            .audience(audience)
            .subject("provider-subject")
            .issueTime(Date.from(now))
            .expirationTime(Date.from(now.plusSeconds(300)))
            .claim("email", "ada@example.com")
            .claim("email_verified", emailVerified)
            .claim("given_name", "Ada")
            .claim("family_name", "Lovelace")
            .build();
        SignedJWT jwt = new SignedJWT(
            new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(key.getKeyID()).build(), claims);
        jwt.sign(new RSASSASigner(key));
        return jwt.serialize();
    }
}
