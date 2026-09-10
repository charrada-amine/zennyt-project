package com.zennyt.engagement.domain.vo;

/**
 * Appréciation portée par l'utilisateur sur une conversation d'aide.
 *
 * <p>Trois valeurs, celles de la maquette. Un jeton fermé plutôt qu'une note sur 5 :
 * l'utilisateur répond en un geste, et trois classes suffisent à repérer ce qui va mal.
 * Une échelle plus fine coûterait un effort de réponse sans rien apporter à la décision
 * qu'on en tire.
 */
public enum HelpChatRating {
    POOR, OK, GREAT
}
