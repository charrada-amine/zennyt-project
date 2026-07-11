package com.zennyt.games.domain.vo;

/**
 * Type de jeu sérieux proposé par le contexte Games.
 *
 * <p>Chaque type correspond à une fiche d'évaluation cognitive. État actuel :
 * {@link #MOVE_FAST}, {@link #PLANIFIK} (3 mini-jeux jouables, profil global /30)
 * et {@link #MEMORY_QUEST} sont implémentés ; {@link #DECISION} est déclaré mais
 * sans logique (figé au contrat pour une extension non cassante) ; la régulation
 * émotionnelle (« Je gère ») n'a pas encore de {@code GameType}.
 */
public enum GameType {
    /** « Je planifie » — planification (3 mini-jeux jouables, /30). */
    PLANIFIK,
    /** « Je bouge » — flexibilité cognitive par switching de règles. */
    MOVE_FAST,
    /** « J'investigue » — mémoire de travail (niveaux + calibrage). */
    MEMORY_QUEST,
    /** « Je décide » — prise de décision (déclaré, non implémenté). */
    DECISION
}
