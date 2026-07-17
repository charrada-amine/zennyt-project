package com.zennyt.recruitment.infrastructure.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** Validation en temps constant du secret partagé utilisé par les callbacks tiers. */
@Component
public class CallbackSecretVerifier {
    private final byte[] expectedSecret;

    public CallbackSecretVerifier(
            @Value("${recruitment.callbacks.secret:}") String expectedSecret) {
        this.expectedSecret = expectedSecret == null
            ? new byte[0] : expectedSecret.getBytes(StandardCharsets.UTF_8);
    }

    public void verify(String providedSecret) {
        byte[] provided = providedSecret == null
            ? new byte[0] : providedSecret.getBytes(StandardCharsets.UTF_8);
        if (expectedSecret.length == 0 || !MessageDigest.isEqual(expectedSecret, provided)) {
            throw new BadCredentialsException("Secret de callback invalide");
        }
    }
}
