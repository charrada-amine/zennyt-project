package com.zennyt.engagement.infrastructure.realtime;

import com.zennyt.engagement.domain.repository.EngagementActorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;
import java.util.UUID;

/**
 * Authentifie l'upgrade WebSocket avec le même JWT que les requêtes HTTP.
 *
 * Le client envoie son bearer token dans l'en-tête HTTP {@code Authorization}
 * lors du handshake (voir {@code WebSocketService} côté mobile). Le token est
 * validé par le {@link JwtDecoder} partagé (signature RS256 + expiration), puis
 * l'acteur est vérifié dans la projection locale {@code engagement.actors}.
 * Le sujet validé est stocké dans les attributs pour que le handshake handler
 * en fasse le {@code Principal} de la session STOMP (routage /user/queue/**).
 */
@Component
@RequiredArgsConstructor
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

    public static final String USER_ID_ATTRIBUTE = "zennyt.userId";

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtDecoder jwtDecoder;
    private final EngagementActorRepository actors;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {
        String token = bearerToken(request);
        if (token == null) {
            return reject(response);
        }
        try {
            Jwt jwt = jwtDecoder.decode(token);
            UUID userId = UUID.fromString(jwt.getSubject());
            boolean active = actors.findById(userId)
                .map(com.zennyt.engagement.domain.model.EngagementActor::active)
                .orElse(false);
            if (!active) {
                return reject(response);
            }
            attributes.put(USER_ID_ATTRIBUTE, userId.toString());
            return true;
        } catch (JwtException | IllegalArgumentException exception) {
            return reject(response);
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler wsHandler, Exception exception) {
        // No-op
    }

    private static boolean reject(ServerHttpResponse response) {
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        return false;
    }

    private static String bearerToken(ServerHttpRequest request) {
        String authorization = request.getHeaders().getFirst("Authorization");
        if (authorization == null || !authorization.startsWith(BEARER_PREFIX)) {
            return null;
        }
        String token = authorization.substring(BEARER_PREFIX.length()).trim();
        return token.isEmpty() ? null : token;
    }
}
