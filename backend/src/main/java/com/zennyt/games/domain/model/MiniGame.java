package com.zennyt.games.domain.model;

import com.zennyt.games.domain.vo.GameType;

/**
 * Mini-jeu appartenant à un {@link GameType}.
 *
 * <p>Planifik est composé de trois mini-jeux complémentaires, chacun noté sur
 * 10 (profil global sur 30). Le {@code maxPoints} du barème est porté ici :
 * c'est une invariante métier issue de la fiche « Je planifie ».
 *
 * <p>Le drapeau {@code playable} distingue les mini-jeux réellement jouables des
 * mini-jeux encore à implémenter. Un mini-jeu non jouable (barème absent) est
 * exclu du calcul de complétion d'une session tant qu'il n'a pas de barème :
 * cela évite qu'une session ne se termine jamais (voir {@code TASK_SCHEDULING}).
 * Réactiver un mini-jeu se limite à repasser son drapeau à {@code true} une fois
 * son barème disponible dans {@code PlanifikScoringService}.
 */
public enum MiniGame {
    /** Planifik #1 — « Le Chemin Optimal ». */
    OPTIMAL_PATH(GameType.PLANIFIK, 10, true),
    /** Planifik #2 — « Ordonnancement de tâches ». Barème dans PlanifikScoringService. */
    TASK_SCHEDULING(GameType.PLANIFIK, 10, true),
    /** Planifik #3 — « Le Puzzle Prévisionnel ». */
    PREVISION_PUZZLE(GameType.PLANIFIK, 10, true),
    /** Move Fast #1 — « Je bouge ». Barème dynamique selon le nombre de réponses. */
    MOVE_FAST_CORE(GameType.MOVE_FAST, 0, true),
    /** Memory Quest — « J'investigue ». Composite /100 (A + B + distraction). */
    MEMORY_QUEST_CORE(GameType.MEMORY_QUEST, 100, true),
    /**
     * « Je Décide » — prise de décision. Score agrégé = SCW /100.
     * Non jouable tant que le {@code DecisionScenarioCatalog} est vide (30 scénarios
     * + étiquetage des options à fournir) — même patron que TASK_SCHEDULING avant
     * implémentation. Repasser à {@code true} une fois le catalogue rempli.
     */
    DECISION_CORE(GameType.DECISION, 100, false);

    private final GameType gameType;
    private final int maxPoints;
    private final boolean playable;

    MiniGame(GameType gameType, int maxPoints, boolean playable) {
        this.gameType = gameType;
        this.maxPoints = maxPoints;
        this.playable = playable;
    }

    public GameType gameType() {
        return gameType;
    }

    public int maxPoints() {
        return maxPoints;
    }

    /**
     * Indique si le mini-jeu dispose d'un barème et peut être joué/enregistré.
     * Un mini-jeu non jouable n'entre pas dans la complétion d'une session.
     */
    public boolean isPlayable() {
        return playable;
    }

    /** Garantit qu'un mini-jeu est cohérent avec le type de la session. */
    public boolean belongsTo(GameType type) {
        return this.gameType == type;
    }
}
