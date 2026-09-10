package com.zennyt.engagement.infrastructure.realtime;

import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;
import org.springframework.http.server.ServerHttpRequest;

import java.security.Principal;
import java.util.Map;

/**
 * Assigne à chaque session STOMP un {@link Principal} égal au sujet JWT validé
 * par {@link JwtHandshakeInterceptor}. Sans ce principal, les destinations
 * utilisateur {@code /user/queue/**} ne peuvent pas être routées par
 * {@code convertAndSendToUser}.
 */
public class JwtPrincipalHandshakeHandler extends DefaultHandshakeHandler {

    @Override
    protected Principal determineUser(ServerHttpRequest request,
                                      WebSocketHandler wsHandler,
                                      Map<String, Object> attributes) {
        String userId = (String) attributes.get(JwtHandshakeInterceptor.USER_ID_ATTRIBUTE);
        return userId == null ? null : () -> userId;
    }
}
