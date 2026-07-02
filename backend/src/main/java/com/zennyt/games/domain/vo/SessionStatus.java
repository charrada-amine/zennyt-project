package com.zennyt.games.domain.vo;

/**
 * Cycle de vie d'une session de jeu.
 *
 * <p>Une session démarre {@link #IN_PROGRESS}, accumule les résultats de
 * mini-jeux, puis passe {@link #COMPLETED} lorsque tous les mini-jeux du type
 * sont joués — c'est à ce moment que le résultat est publié.
 */
public enum SessionStatus {
    IN_PROGRESS, COMPLETED, ABANDONED
}
