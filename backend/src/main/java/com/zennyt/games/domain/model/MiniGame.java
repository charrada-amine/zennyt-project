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
    DECISION_CORE(GameType.DECISION, 100, false),
    /**
     * « Emotional Radar » — reconnaissance émotionnelle. Barème <b>dynamique</b>
     * (comme {@code MOVE_FAST_CORE}, d'où {@code maxPoints = 0}) : le maximum vaut
     * {@code scènes jouées × 9}, le {@code Score} le porte lui-même. Les points
     * proviennent des réponses notées serveur scène par scène, jamais du client.
     */
    EMOTIONAL_RADAR_CORE(GameType.EMOTIONAL_REGULATION, 0, true),
    /**
     * « Reflective Pause » — contrôle de l'impulsivité sous pression.
     * Temps contrôlé /3 + réponses non impulsives /4 + prise de recul /3.
     */
    REFLECTIVE_PAUSE_CORE(GameType.EMOTIONAL_REGULATION, 10, true),
    /**
     * « Je continue » — protocole Long Rosvold X/AX. Le score provisoire /100
     * ne dépend que des balanced accuracies des deux phases de test.
     */
    CONTINUOUS_ATTENTION_CORE(GameType.CONTINUOUS_ATTENTION, 100, true),
    /** « Je coordonne » — tracking visuomoteur, précision globale /100 provisoire. */
    COORDINATION_TRACKING_CORE(GameType.VISUOMOTOR_COORDINATION, 100, true);

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
