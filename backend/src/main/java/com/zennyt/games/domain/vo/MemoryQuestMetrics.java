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
    int finalLevel,
    boolean sessionCompleted,
    List<MemoryTaskResult> tasks
) implements GameMetrics {

    public MemoryQuestMetrics {
        requireNonNegative(observedDigits, "observedDigits");
        requireRange(correctSameDigits, observedDigits, "correctSameDigits");
        requireRange(correctReverseDigits, observedDigits, "correctReverseDigits");
        requireNonNegative(highestSequenceLength, "highestSequenceLength");
        requireNonNegative(objectCount, "objectCount");
        requireRange(restoreCorrect, objectCount, "restoreCorrect");
        requireNonNegative(manipulationCount, "manipulationCount");
        requireNonNegative(afterDistractionObserved, "afterDistractionObserved");
        requireRange(afterDistractionCorrect, afterDistractionObserved, "afterDistractionCorrect");
        if (observedDigits == 0) {
            throw new IllegalArgumentException("observedDigits doit être > 0 (Mission A jouée)");
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
        this(observedDigits, correctSameDigits, correctReverseDigits, highestSequenceLength,
            objectCount, restoreCorrect, manipulationCount, distractionPlayed,
            afterDistractionObserved, afterDistractionCorrect, distractionQuestionCorrect,
            1, true, List.of());
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
            .filter(t -> t.responseTimeMs()
                > com.zennyt.games.domain.config.MemoryQuestConfig.adjustedTaskTimeoutMs(calibrationOffsetMs))
            .count();
    }
}
