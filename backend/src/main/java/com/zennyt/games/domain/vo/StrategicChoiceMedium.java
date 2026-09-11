package com.zennyt.games.domain.vo;

/**
 * Support par lequel une situation « Choix Stratégiques » est présentée.
 *
 * <p>Les soixante fiches de la banque décrivent une mini-vidéo ; aucune n'est
 * livrée comme message écrit. Le champ existe parce que le cahier des charges
 * prévoit les deux supports, et parce qu'un délai de réponse ne se compare
 * qu'à support égal.
 */
public enum StrategicChoiceMedium {
    VIDEO,
    WRITTEN
}
