package com.zennyt.games.domain.config;

/**
 * Configuration du mini-jeu « Ordonnancement de tâches » (Planifik #2 — Planification).
 *
 * <p>Java pur, sans Spring : invariantes métier issues de la fiche
 * « JE PLANIFIE — Mini-jeu 2 ». Le barème est <b>calculé côté serveur</b>
 * ({@code PlanifikScoringService}) — le client n'envoie jamais de points. Le mock
 * mobile ({@code games_mock_repository.dart}) doit reproduire ces valeurs.
 *
 * <p>Barème /10 en quatre composantes, selon le référentiel client
 * « Planning journalier » : dépendances (3) + gestion du temps (3) + cohérence
 * séquentielle (2) + autorégulation (2). Les trois premières se calculent sur
 * des RATIOS, plus sur des tout-ou-rien : un joueur qui respecte huit
 * contraintes sur neuf ne vaut pas celui qui n'en respecte aucune.
 */
public final class TaskSchedulingConfig {

    private TaskSchedulingConfig() {
    }

    // ── Poids du barème (3 + 3 + 2 + 2 = /10) ────────────────────────────────

    /** Dépendances respectées — au prorata, moins les violations directes. */
    public static final double DEPENDENCIES_POINTS = 3.0;

    /** Gestion du temps — au prorata du n RÉEL de l'univers. */
    public static final double TIME_CONSTRAINTS_POINTS = 3.0;

    /** Cohérence séquentielle — collisions et temps mort. */
    public static final double PLANNING_COHERENCE_MAX_POINTS = 2.0;

    /** Autorégulation — nature et nombre des corrections. */
    public static final double ADJUSTMENT_MAX_POINTS = 2.0;

    /** Maximum du barème du mini-jeu. */
    public static final int MAX_POINTS = 10;

    // ── Composante 1 : dépendances ───────────────────────────────────────────

    /**
     * Pénalité par violation DIRECTE — « tâche lancée sans que son prérequis
     * soit terminé ».
     *
     * <p>Le référentiel la distingue d'un simple sous-optimum d'ordre : c'est
     * une erreur de règle, pas un mauvais arbitrage (Tour de Londres, Shallice
     * 1982). La composante ne descend jamais sous zéro.
     */
    public static final double DEPENDENCY_DIRECT_VIOLATION_PENALTY = 1.0;

    // ── Composante 3 : cohérence séquentielle ────────────────────────────────

    /** Aucune collision → ce point est acquis. */
    public static final double COHERENCE_COLLISION_POINTS = 1.0;

    /** Temps mort sous ce seuil → le second point entier. */
    public static final double DEAD_TIME_FULL_POINT_RATIO = 0.10;

    /** Temps mort jusqu'à ce seuil → un demi-point ; au-delà → rien. */
    public static final double DEAD_TIME_HALF_POINT_RATIO = 0.25;

    // ── Composante 4 : autorégulation ────────────────────────────────────────
    //
    // Le référentiel : « 2 pts si 0-1 correction proactive ; 1 pt si 2-3
    // corrections mélangées ; 0 pt si > 3 corrections réactives ». Un nombre nul
    // d'ajustements n'est pas forcément optimal — il peut signaler une absence
    // de détection d'erreur (Miyake et al., 2000).

    /** Jusqu'à ce total de corrections → 2 pts. */
    public static final int SELF_REGULATION_LOW_TOTAL = 1;

    /** Jusqu'à ce total → 1 pt. */
    public static final int SELF_REGULATION_MID_TOTAL = 3;

    /** Au-delà de ce nombre de corrections RÉACTIVES → 0 pt. */
    public static final int SELF_REGULATION_REACTIVE_LIMIT = 3;

    // ── Décisions produit ────────────────────────────────────────────────────

    /** Nombre de tâches d'un univers — la banque livrée en compte 11 ou 12. */
    public static final int TOTAL_TASKS_MIN = 10;
    public static final int TOTAL_TASKS_MAX = 12;

    /** {@code task_dependencies_enabled} = true (critère le plus lourd du barème). */
    public static final boolean TASK_DEPENDENCIES_ENABLED = true;

    /**
     * Tolérance des ancrages « Bloc horaire fixe », en minutes.
     *
     * <p>Appliquée par le moteur d'ordonnancement mobile, qui décide du respect
     * de chaque contrainte ; reprise ici pour que la valeur ait une seule
     * source déclarée.
     */
    public static final int FIXED_BLOCK_TOLERANCE_MIN = 5;

    /**
     * Composante 1 — dépendances, sur {@value #DEPENDENCIES_POINTS} points.
     *
     * <p>{@code 3 × (respectées / total) − 1 par violation directe}, plancher 0.
     * Sans arêtes de dépendance, la composante est acquise : on ne pénalise pas
     * un univers qui n'en a pas.
     */
    public static double dependencyScore(int respected, int total, int directViolations) {
        if (total <= 0) {
            return DEPENDENCIES_POINTS;
        }
        double ratio = DEPENDENCIES_POINTS * respected / total;
        double penalised = ratio - DEPENDENCY_DIRECT_VIOLATION_PENALTY * directViolations;
        return Math.max(0.0, penalised);
    }

    /**
     * Composante 2 — gestion du temps, sur {@value #TIME_CONSTRAINTS_POINTS}.
     *
     * <p>{@code 3 × (respectées / n)}, où n est le nombre RÉEL de contraintes
     * horaires de l'univers tiré. Le référentiel y insiste : n varie de 5 à 7,
     * et diviser par une constante rendrait deux passations incomparables.
     */
    public static double timeScore(int respected, int constraintCount) {
        if (constraintCount <= 0) {
            return TIME_CONSTRAINTS_POINTS;
        }
        return TIME_CONSTRAINTS_POINTS * respected / constraintCount;
    }

    /**
     * Composante 3 — cohérence séquentielle, sur
     * {@value #PLANNING_COHERENCE_MAX_POINTS}.
     *
     * <p>Un point si aucune collision, plus un point modulé par le temps mort :
     * moins de 10 % de l'amplitude → 1 pt, 10 à 25 % → 0,5 pt, au-delà → 0.
     */
    public static double coherenceScore(boolean collisionFree, double deadTimeRatio) {
        double points = collisionFree ? COHERENCE_COLLISION_POINTS : 0.0;
        if (deadTimeRatio < DEAD_TIME_FULL_POINT_RATIO) {
            points += 1.0;
        } else if (deadTimeRatio <= DEAD_TIME_HALF_POINT_RATIO) {
            points += 0.5;
        }
        return points;
    }

    /**
     * Composante 4 — autorégulation, sur {@value #ADJUSTMENT_MAX_POINTS}.
     *
     * <p>Le référentiel distingue les corrections PROACTIVES — décidées avant
     * que le jeu n'ait rien signalé — des RÉACTIVES, déclenchées par une erreur
     * affichée. Trop de réactives l'emporte sur le total : un joueur qui ne
     * corrige que sous alerte ne démontre pas la même autorégulation.
     *
     * <p>Les seuils du référentiel — 1 puis 3 corrections — ont été calibrés
     * sur UN planning. Une partie en enchaîne plusieurs et le client en envoie
     * la somme : on multiplie donc les seuils par le nombre de plannings, sinon
     * un barème de manche s'appliquerait à un total de partie et toute partie
     * où le joueur se reprend une fois par manche tomberait à zéro.
     *
     * @param plannings nombre de plannings de la partie ; 1 pour un client qui
     *                  ne le précise pas, ce qui redonne exactement l'ancien
     *                  barème.
     */
    public static double selfRegulationScore(int proactive, int reactive, int plannings) {
        int n = Math.max(1, plannings);
        if (reactive > SELF_REGULATION_REACTIVE_LIMIT * n) {
            return 0.0;
        }
        int total = proactive + reactive;
        if (total <= SELF_REGULATION_LOW_TOTAL * n) {
            return ADJUSTMENT_MAX_POINTS;
        }
        if (total <= SELF_REGULATION_MID_TOTAL * n) {
            return 1.0;
        }
        return 0.0;
    }
}
