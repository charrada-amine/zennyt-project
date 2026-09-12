package com.zennyt.identity.domain.model;

import java.time.Instant;

/**
 * Préférences d'application d'un compte, synchronisées côté serveur :
 * notifications et accessibilité (contraste, taille de texte). Une seule ligne
 * par compte ; en son absence, {@link #defaults(long)} fournit les valeurs par
 * défaut sans persistance.
 */
public record UserPreferences(long userId, boolean notificationsEnabled, boolean highContrast,
                              int textSizePx, Instant updatedAt) {
    public static final int MIN_TEXT_SIZE_PX = 10;
    public static final int MAX_TEXT_SIZE_PX = 30;
    public static final int DEFAULT_TEXT_SIZE_PX = 18;

    public UserPreferences {
        if (textSizePx < MIN_TEXT_SIZE_PX || textSizePx > MAX_TEXT_SIZE_PX) {
            throw new IllegalArgumentException(
                "La taille de texte doit être entre " + MIN_TEXT_SIZE_PX + " et " + MAX_TEXT_SIZE_PX);
        }
    }

    /** Valeurs par défaut renvoyées quand le compte n'a jamais rien enregistré. */
    public static UserPreferences defaults(long userId) {
        return new UserPreferences(userId, true, true, DEFAULT_TEXT_SIZE_PX, Instant.now());
    }

    public UserPreferences with(boolean notificationsEnabled, boolean highContrast, int textSizePx,
                                Instant updatedAt) {
        return new UserPreferences(userId, notificationsEnabled, highContrast, textSizePx, updatedAt);
    }
}
