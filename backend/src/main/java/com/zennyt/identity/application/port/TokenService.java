package com.zennyt.identity.application.port;

import com.zennyt.identity.domain.model.User;

public interface TokenService {
    TokenPair issue(User user);
    TokenPair rotate(String refreshToken);
    void revoke(String refreshToken);

    /** Révoque toutes les sessions de rafraîchissement de l'utilisateur (déconnexion globale). */
    void revokeAll(Long userId);

    record TokenPair(String accessToken, String refreshToken, String tokenType, long expiresIn) {}
}
