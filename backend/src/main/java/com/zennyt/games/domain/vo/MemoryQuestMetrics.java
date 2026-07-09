package com.zennyt.games.domain.vo;

/**
 * Mesures brutes de « J'investigue » (mémoire de travail).
 *
 * <p>Le client envoie des <b>mesures</b> par tâche (jamais de points) : rappel
 * même ordre / inverse (Mission A), restauration d'objets (Mission B), rappel
 * après distraction (Phase 3). Le domaine ({@code MemoryQuestScoringService})
 * note chaque tâche 0–5 puis calcule le composite /100.
 *
 * <p>La Mission B est jouée si {@code objectCount > 0} ; la distraction si
 * {@code distractionPlayed}.
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
    boolean distractionQuestionCorrect
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
}
