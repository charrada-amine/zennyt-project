package com.zennyt.games.domain.vo;

import java.util.List;

/**
 * Mesures brutes de « J'investigue » (mémoire de travail).
 *
 * <p>Le client envoie des <b>mesures</b> par tâche (jamais de points) : rappel
 * même ordre / inverse (Mission A), restauration d'objets (Mission B), rappel
 * après distraction (Phase 3). Le domaine ({@code MemoryQuestScoringService})
 * note chaque tâche 0–5 puis calcule le composite /100.
 *
 * <p>La Mission B est jouée si {@code objectCount > 0} ; la distraction si
 * {@code distractionPlayed}. Le système de NIVEAUX est porté par {@code finalLevel}
 * (1–7) et la liste {@code tasks} (une entrée par instance de tâche, avec timing) :
 * la présence de {@code tasks} active l'ajustement du TIMEOUT par le calibrage
 * (le score dépend alors du temps). Sans {@code tasks}, le composite est calculé
 * sur les agrégats plats (compatibilité, sans timeout).
 *
 * @param observedDigits               nb de chiffres observés (Mission A, hors distraction)
 * @param correctSameDigits            chiffres corrects au rappel même ordre
 * @param correctReverseDigits         chiffres corrects au rappel inverse
 * @param highestSequenceLength        empan maximal atteint
 * @param objectCount                  nb d'objets (Mission B ; 0 si non jouée)
 * @param restoreCorrect               positions correctes à la restauration
 * @param manipulationCount            nb de manipulations automatiques observées
 * @param distractionPlayed            true si la phase de distraction a été jouée
 * @param afterDistractionObserved     chiffres à protéger pendant la distraction
 * @param afterDistractionCorrect      chiffres corrects au rappel après distraction
 * @param distractionQuestionCorrect   réponse à la question rapide correcte (indicateur)
 * @param finalLevel                   niveau atteint (1–7)
 * @param sessionCompleted             false = abandon avant la condition de fin
 * @param tasks                        tâches par instance (avec timing) ; vide = mode agrégat
 */
public record MemoryQuestMetrics(
    MemoryQuestMode mode,
    int observedDigits,
    int correctSameDigits,
    int correctReverseDigits,
    int highestSequenceLength,
    int objectCount,
    int restoreCorrect,
    int manipulationCount,
    boolean distractionPlayed,
    int afterDistractionObserved,
    int afterDistractionCorrect,
    boolean distractionQuestionCorrect,
    int distractionChallengesPlayed,
    int distractionChallengesSolved,
    int distractionTimeouts,
    int finalLevel,
    boolean sessionCompleted,
    List<MemoryTaskResult> tasks
) implements GameMetrics {

    public MemoryQuestMetrics {
        mode = mode == null ? MemoryQuestMode.FULL : mode;
        requireNonNegative(observedDigits, "observedDigits");
        requireRange(correctSameDigits, observedDigits, "correctSameDigits");
        requireRange(correctReverseDigits, observedDigits, "correctReverseDigits");
        requireNonNegative(highestSequenceLength, "highestSequenceLength");
        requireNonNegative(objectCount, "objectCount");
        requireRange(restoreCorrect, objectCount, "restoreCorrect");
        requireNonNegative(manipulationCount, "manipulationCount");
        requireNonNegative(afterDistractionObserved, "afterDistractionObserved");
        requireRange(afterDistractionCorrect, afterDistractionObserved, "afterDistractionCorrect");
        requireNonNegative(distractionChallengesPlayed, "distractionChallengesPlayed");
        requireRange(distractionChallengesSolved, distractionChallengesPlayed,
            "distractionChallengesSolved");
        requireRange(distractionTimeouts, distractionChallengesPlayed, "distractionTimeouts");
        // La preuve qu'une mission a été jouée dépend du MODE : le jeu des
        // images n'observe aucun chiffre, celui des chiffres aucun objet.
        // Exiger `observedDigits > 0` sans condition rejetait toute partie
        // d'images à la soumission.
        if (mode.playsDigits() && observedDigits == 0) {
            throw new IllegalArgumentException(
                "observedDigits doit être > 0 quand le mode joue les chiffres");
        }
        if (!mode.playsDigits() && objectCount == 0) {
            throw new IllegalArgumentException(
                "objectCount doit être > 0 quand le mode joue les images");
        }
        if (!mode.playsDigits() && (correctSameDigits > 0 || correctReverseDigits > 0
            || highestSequenceLength > 0)) {
            throw new IllegalArgumentException(
                "le mode IMAGES ne peut porter aucune mesure de chiffres");
        }
        if (distractionPlayed && afterDistractionObserved == 0) {
            throw new IllegalArgumentException(
                "afterDistractionObserved doit être > 0 quand distractionPlayed=true");
        }
        if (finalLevel < 1) {
            throw new IllegalArgumentException("finalLevel doit être >= 1");
        }
        tasks = tasks == null ? List.of() : List.copyOf(tasks);
    }

    /** Mesures d'une partie d'IMAGES (aucune mesure de chiffres). */
    public static MemoryQuestMetrics images(int objectCount, int restoreCorrect,
                                            boolean distractionPlayed,
                                            int afterDistractionObserved,
                                            int afterDistractionCorrect,
                                            int challengesPlayed, int challengesSolved,
                                            int challengeTimeouts, int finalLevel,
                                            boolean sessionCompleted,
                                            List<MemoryTaskResult> tasks) {
        return new MemoryQuestMetrics(MemoryQuestMode.IMAGES, 0, 0, 0, 0,
            objectCount, restoreCorrect, 0, distractionPlayed,
            afterDistractionObserved, afterDistractionCorrect, false,
            challengesPlayed, challengesSolved, challengeTimeouts,
            finalLevel, sessionCompleted, tasks);
    }

    /**
     * Fabrique de compatibilité (agrégats plats sans système de niveaux) :
     * {@code finalLevel = 1}, {@code sessionCompleted = true}, aucune tâche timée.
     * Préserve le comportement historique (composite inchangé).
     */
    public MemoryQuestMetrics(int observedDigits, int correctSameDigits, int correctReverseDigits,
                              int highestSequenceLength, int objectCount, int restoreCorrect,
                              int manipulationCount, boolean distractionPlayed,
                              int afterDistractionObserved, int afterDistractionCorrect,
                              boolean distractionQuestionCorrect) {
        this(MemoryQuestMode.FULL, observedDigits, correctSameDigits, correctReverseDigits,
            highestSequenceLength, objectCount, restoreCorrect, manipulationCount,
            distractionPlayed, afterDistractionObserved, afterDistractionCorrect,
            distractionQuestionCorrect, 0, 0, 0, 1, true, List.of());
    }

    /** Compatibilité : mesures complètes sans mode ni compteurs de distraction. */
    public MemoryQuestMetrics(int observedDigits, int correctSameDigits, int correctReverseDigits,
                              int highestSequenceLength, int objectCount, int restoreCorrect,
                              int manipulationCount, boolean distractionPlayed,
                              int afterDistractionObserved, int afterDistractionCorrect,
                              boolean distractionQuestionCorrect, int finalLevel,
                              boolean sessionCompleted, List<MemoryTaskResult> tasks) {
        this(MemoryQuestMode.FULL, observedDigits, correctSameDigits, correctReverseDigits,
            highestSequenceLength, objectCount, restoreCorrect, manipulationCount,
            distractionPlayed, afterDistractionObserved, afterDistractionCorrect,
            distractionQuestionCorrect, 0, 0, 0, finalLevel, sessionCompleted, tasks);
    }

    private static void requireNonNegative(int v, String field) {
        if (v < 0) {
            throw new IllegalArgumentException(field + " doit être >= 0");
        }
    }

    private static void requireRange(int v, int max, String field) {
        if (v < 0 || v > max) {
            throw new IllegalArgumentException(field + " doit être dans [0, " + max + "]");
        }
    }

    public boolean missionBPlayed() {
        return objectCount > 0;
    }

    public double sameAccuracy() {
        return observedDigits == 0 ? 0.0 : correctSameDigits / (double) observedDigits;
    }

    public double reverseAccuracy() {
        return observedDigits == 0 ? 0.0 : correctReverseDigits / (double) observedDigits;
    }

    public double restoreAccuracy() {
        return objectCount == 0 ? 0.0 : restoreCorrect / (double) objectCount;
    }

    public double afterDistractionAccuracy() {
        return afterDistractionObserved == 0 ? 0.0 : afterDistractionCorrect / (double) afterDistractionObserved;
    }

    /** Part des tâches parasites résolues dans les temps. */
    public double distractionSolveRate() {
        return distractionChallengesPlayed == 0
            ? 0.0
            : distractionChallengesSolved / (double) distractionChallengesPlayed;
    }

    /** true si des timings par tâche sont fournis (active l'ajustement timeout). */
    public boolean hasTaskTimings() {
        return !tasks.isEmpty();
    }

    /**
     * Nombre de tâches en échec par DÉPASSEMENT DE TEMPS pour un offset donné.
     * (Voir {@code MemoryQuestConfig.isTaskTimedOut}.)
     */
    public int timeoutTaskCount(double calibrationOffsetMs) {
        return (int) tasks.stream()
            .filter(t -> isTimedOut(t, calibrationOffsetMs))
            .count();
    }

    /**
     * Une tâche a-t-elle dépassé SON délai ?
     *
     * <p>Une tâche parasite est jugée sur le budget de son niveau, pas sur
     * {@code MAX_TASK_TIME_MS} : sans cette distinction, une épreuve résolue en
     * 8 s — dans les temps vis-à-vis de son chronomètre de 12 s — serait voidée
     * par le seuil générique de 6 s, punissant deux fois un essai réussi.
     */
    public static boolean isTimedOut(MemoryTaskResult t, double calibrationOffsetMs) {
        if (t.kind() == MemoryTaskKind.DISTRACTION_CHALLENGE) {
            return com.zennyt.games.domain.config.MemoryQuestConfig
                .isDistractionTimedOut(t.responseTimeMs(), t.level(), calibrationOffsetMs);
        }
        return com.zennyt.games.domain.config.MemoryQuestConfig
            .isTaskTimedOut(t.responseTimeMs(), calibrationOffsetMs);
    }
}
