package com.zennyt.identity.infrastructure.security;

import com.zennyt.identity.application.port.SocialIdentityVerifier;
import com.zennyt.identity.domain.model.SocialProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.oauth2.core.*;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class SocialIdentityJwtVerifier implements SocialIdentityVerifier {
    private static final OAuth2Error INVALID_TOKEN =
        new OAuth2Error(OAuth2ErrorCodes.INVALID_TOKEN, "Invalid token claims", null);

    private final Map<SocialProvider, JwtDecoder> decoders;

    public SocialIdentityJwtVerifier(
        @Value("${identity.social.google.issuer}") String googleIssuer,
        @Value("${identity.social.google.jwk-set-uri}") String googleJwkSetUri,
        @Value("${identity.social.google.client-ids:}") String googleClientIds,
        @Value("${identity.social.apple.issuer}") String appleIssuer,
        @Value("${identity.social.apple.jwk-set-uri}") String appleJwkSetUri,
        @Value("${identity.social.apple.client-ids:}") String appleClientIds
    ) {
        EnumMap<SocialProvider, JwtDecoder> configured = new EnumMap<>(SocialProvider.class);
        addDecoder(configured, SocialProvider.GOOGLE, googleIssuer, googleJwkSetUri, googleClientIds);
        addDecoder(configured, SocialProvider.APPLE, appleIssuer, appleJwkSetUri, appleClientIds);
        this.decoders = Map.copyOf(configured);
    }

    @Override
    public VerifiedIdentity verify(SocialProvider provider, String idToken) {
        JwtDecoder decoder = decoders.get(provider);
        if (decoder == null) {
            throw new BadCredentialsException(provider + " login is not configured");
        }

        try {
            Jwt jwt = decoder.decode(idToken);
            if (jwt.getSubject() == null || jwt.getSubject().isBlank()) {
                throw new BadCredentialsException("Identity token subject is missing");
            }
            return new VerifiedIdentity(
                jwt.getSubject(),
                jwt.getClaimAsString("email"),
                booleanClaim(jwt, "email_verified"),
                jwt.getClaimAsString("given_name"),
                jwt.getClaimAsString("family_name"),
                jwt.getClaimAsString("picture")
            );
        } catch (JwtException ex) {
            throw new BadCredentialsException("Invalid " + provider + " identity token", ex);
        }
    }

    private static void addDecoder(Map<SocialProvider, JwtDecoder> decoders,
                                   SocialProvider provider, String issuer, String jwkSetUri,
                                   String clientIdsValue) {
        Set<String> clientIds = parseClientIds(clientIdsValue);
        if (clientIds.isEmpty()) {
            return;
        }

        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build();
        OAuth2TokenValidator<Jwt> audienceValidator = jwt -> {
            boolean audienceAccepted = jwt.getAudience().stream().anyMatch(clientIds::contains);
            String authorizedParty = jwt.getClaimAsString("azp");
            boolean authorizedPartyAccepted =
                authorizedParty == null || clientIds.contains(authorizedParty);
            return audienceAccepted && authorizedPartyAccepted
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(INVALID_TOKEN);
        };
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
            JwtValidators.createDefaultWithIssuer(issuer), audienceValidator));
        decoders.put(provider, decoder);
    }

    static Set<String> parseClientIds(String value) {
        if (value == null || value.isBlank()) {
            return Set.of();
        }
        Set<String> clientIds = new LinkedHashSet<>();
        Arrays.stream(value.split(","))
            .map(String::trim)
            .filter(clientId -> !clientId.isEmpty())
            .forEach(clientIds::add);
        return Set.copyOf(clientIds);
    }

    private static boolean booleanClaim(Jwt jwt, String name) {
        Object value = jwt.getClaim(name);
        return value instanceof Boolean bool ? bool : Boolean.parseBoolean(String.valueOf(value));
    }
}
