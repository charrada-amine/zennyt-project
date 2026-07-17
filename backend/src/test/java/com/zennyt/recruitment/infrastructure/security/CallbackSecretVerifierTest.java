package com.zennyt.recruitment.infrastructure.security;

import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.BadCredentialsException;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CallbackSecretVerifierTest {

    @Test
    void acceptsOnlyExactConfiguredSecret() {
        var verifier = new CallbackSecretVerifier("correct-secret");

        assertThatCode(() -> verifier.verify("correct-secret")).doesNotThrowAnyException();
        assertThatThrownBy(() -> verifier.verify("wrong-secret"))
            .isInstanceOf(BadCredentialsException.class);
        assertThatThrownBy(() -> verifier.verify(null))
            .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void failsClosedWhenSecretIsNotConfigured() {
        assertThatThrownBy(() -> new CallbackSecretVerifier("").verify("anything"))
            .isInstanceOf(BadCredentialsException.class);
    }
}
