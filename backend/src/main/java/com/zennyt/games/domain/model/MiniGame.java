package com.zennyt.games.domain.model;

import com.zennyt.games.domain.vo.GameType;

/**
 * Mini-jeu appartenant à un {@link GameType}.
 *
 * <p>Planifik est composé de trois mini-jeux complémentaires, chacun noté sur
 * 10 (profil global sur 30). Le {@code maxPoints} du barème est porté ici :
 * c'est une invariante métier issue de la fiche « Je planifie ».
 */
public enum MiniGame {
    /** Planifik #1 — « Le Chemin Optimal ». */
    OPTIMAL_PATH(GameType.PLANIFIK, 10),
    /** Planifik #2 — « Ordonnancement de tâches » (à venir). */
    TASK_SCHEDULING(GameType.PLANIFIK, 10),
    /** Planifik #3 — « Le Puzzle Prévisionnel » (à venir). */
    PREVISION_PUZZLE(GameType.PLANIFIK, 10),
    /** Move Fast #1 — « Je bouge ». Barème dynamique selon le nombre de réponses. */
    MOVE_FAST_CORE(GameType.MOVE_FAST, 0);

    private final GameType gameType;
    private final int maxPoints;

    MiniGame(GameType gameType, int maxPoints) {
        this.gameType = gameType;
        this.maxPoints = maxPoints;
    }

    public GameType gameType() {
        return gameType;
    }

    public int maxPoints() {
        return maxPoints;
    }

    /** Garantit qu'un mini-jeu est cohérent avec le type de la session. */
    public boolean belongsTo(GameType type) {
        return this.gameType == type;
    }
}
