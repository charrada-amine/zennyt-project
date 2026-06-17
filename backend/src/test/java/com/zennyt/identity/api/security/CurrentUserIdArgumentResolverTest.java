package com.zennyt.identity.api.security;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CurrentUserIdArgumentResolverTest {
    private final CurrentUserIdArgumentResolver resolver = new CurrentUserIdArgumentResolver();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void resolvesUuidFromJwtSubject() throws Exception {
        UUID userId = UUID.randomUUID();
        Jwt jwt = Jwt.withTokenValue("token")
            .header("alg", "none")
            .subject(userId.toString())
            .issuedAt(Instant.now())
            .expiresAt(Instant.now().plusSeconds(60))
            .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));

        Object resolved = resolver.resolveArgument(parameter("currentUser"), null, null, null);

        assertThat(resolved).isEqualTo(userId);
    }

    @Test
    void supportsOnlyCurrentUserIdUuidParameters() throws Exception {
        assertThat(resolver.supportsParameter(parameter("currentUser"))).isTrue();
        assertThat(resolver.supportsParameter(parameter("plainUuid"))).isFalse();
        assertThat(resolver.supportsParameter(parameter("wrongType"))).isFalse();
    }

    @Test
    void failsWhenJwtPrincipalIsMissing() throws Exception {
        assertThatThrownBy(() -> resolver.resolveArgument(parameter("currentUser"), null, null, null))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("JWT principal");
    }

    @SuppressWarnings("unused")
    private void sample(@CurrentUserId UUID currentUser, UUID plainUuid,
                        @CurrentUserId String wrongType) {
    }

    private static MethodParameter parameter(String name) throws Exception {
        Method method = CurrentUserIdArgumentResolverTest.class.getDeclaredMethod(
            "sample", UUID.class, UUID.class, String.class);
        return new MethodParameter(method, switch (name) {
            case "currentUser" -> 0;
            case "plainUuid" -> 1;
            case "wrongType" -> 2;
            default -> throw new IllegalArgumentException(name);
        });
    }
}
