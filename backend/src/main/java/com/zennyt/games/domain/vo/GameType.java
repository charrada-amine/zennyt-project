package com.zennyt.games.domain.vo;

/**
 * Type de jeu sérieux proposé par le contexte Games.
 *
 * <p>Chaque type correspond à une fiche d'évaluation cognitive. Seul
 * {@link #PLANIFIK} est implémenté pour l'instant ; les autres sont déclarés
 * pour figer le contrat et permettre une extension sans changement cassant.
 */
public enum GameType {
    /** « Je planifie » — évalue la planification (3 mini-jeux). */
    PLANIFIK,
    /** « J'investigue » — évalue la mémoire de travail (à venir). */
    MEMORY_QUEST,
    /** « Je décide » — évalue la prise de décision (à venir). */
    DECISION
}
