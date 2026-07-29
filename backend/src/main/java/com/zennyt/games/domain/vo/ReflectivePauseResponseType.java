package com.zennyt.games.domain.vo;

/**
 * Réponse choisie face à un moment de pression dans « Reflective Pause ».
 *
 * <p>Le client transmet uniquement ce choix brut. La qualité de la réponse et
 * les points sont dérivés côté serveur depuis le catalogue du handoff.
 */
public enum ReflectivePauseResponseType {
    RESPOND_IMPULSIVELY,
    BREATHE_ANALYZE,
    WAIT,
    ASK_FOR_MORE_INFORMATION,
    REFORMULATE_CALMLY
}
