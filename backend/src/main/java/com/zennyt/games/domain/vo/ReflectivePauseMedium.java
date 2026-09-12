package com.zennyt.games.domain.vo;

/**
 * Support par lequel une situation du « Temps Réflexif » est présentée.
 *
 * <p>Le client attend « selon le scénario, une vidéo OU un message écrit ». Le
 * support est une donnée de la situation, et il remonte avec les mesures parce
 * qu'il conditionne le délai de réponse observé.
 */
public enum ReflectivePauseMedium {

    /** Interaction en face à face, rejouée par une mini-vidéo. */
    VIDEO,

    /** SMS, chat ou e-mail : le message est affiché. */
    WRITTEN
}
