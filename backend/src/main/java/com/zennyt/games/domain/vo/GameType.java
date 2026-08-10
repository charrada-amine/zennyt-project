package com.zennyt.games.domain.vo;

/**
 * Type de jeu sérieux proposé par le contexte Games.
 *
 * <p>Chaque type correspond à une fiche d'évaluation cognitive. État actuel :
 * {@link #MOVE_FAST}, {@link #PLANIFIK} (3 mini-jeux jouables, profil global /30),
 * {@link #MEMORY_QUEST}, {@link #EMOTIONAL_REGULATION} et
 * {@link #CONTINUOUS_ATTENTION}, {@link #VISUOMOTOR_COORDINATION} et
 * {@link #VISUOSPATIAL_MEMORY} sont implémentés ;
 * {@link #DECISION} est déclaré mais sans logique (figé au contrat pour une
 * extension non cassante).
 */
public enum GameType {
    /** « Je planifie » — planification (3 mini-jeux jouables, /30). */
    PLANIFIK,
    /** « Je bouge » — flexibilité cognitive par switching de règles. */
    MOVE_FAST,
    /** « J'investigue » — mémoire de travail (niveaux + calibrage). */
    MEMORY_QUEST,
    /** « Je décide » — prise de décision (déclaré, non implémenté). */
    DECISION,
    /**
     * « Je gère » — régulation émotionnelle. Héberge les mini-jeux
     * {@code EMOTIONAL_RADAR_CORE} et {@code REFLECTIVE_PAUSE_CORE}, sur le
     * modèle de {@link #PLANIFIK} qui héberge ses trois mini-jeux.
     */
    EMOTIONAL_REGULATION,
    /**
     * « Je continue » — attention soutenue et sélective, protocole Long
     * Rosvold X/AX. Ce type reste distinct de MOVE_FAST afin de préserver
     * l'agrégat, le barème et les événements historiques de ce dernier.
     */
    CONTINUOUS_ATTENTION,
    /**
     * « Je coordonne » — coordination visuomotrice sur une trajectoire carrée
     * fixe. Type indépendant afin de préserver les sessions Move Fast.
     */
    VISUOMOTOR_COORDINATION,
    /**
     * « Je place » — liaison objet-position et mémoire de travail
     * visuospatiale. Type indépendant afin de préserver Memory Quest.
     */
    VISUOSPATIAL_MEMORY
}
