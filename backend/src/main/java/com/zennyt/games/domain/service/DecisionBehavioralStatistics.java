package com.zennyt.games.domain.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Statistiques descriptives partagées par BART et IST.
 *
 * <p>PARITÉ MOCK ⇄ BACKEND : l'arrondi est {@code floor(x × 10⁴ + 0,5) / 10⁴} des
 * deux côtés — et non {@code Math.round}/{@code round()}, dont le traitement des
 * demi-valeurs négatives diffère entre Java et Dart. Miroir mobile :
 * {@code mobile/lib/features/games/data/decision_behavioral_scoring.dart}.
 */
public final class DecisionBehavioralStatistics {

    private DecisionBehavioralStatistics() {
    }

    /** Arrondi à 4 décimales, identique en Java et en Dart. */
    public static double round4(double value) {
        return Math.floor(value * 10_000.0 + 0.5) / 10_000.0;
    }

    /** Moyenne arrondie, ou null pour une liste vide. */
    public static Double meanOrNull(List<? extends Number> values) {
        if (values.isEmpty()) return null;
        double sum = 0.0;
        for (Number value : values) sum += value.doubleValue();
        return round4(sum / values.size());
    }

    /** Moyenne arrondie, 0 pour une liste vide. */
    public static double meanOrZero(List<? extends Number> values) {
        Double mean = meanOrNull(values);
        return mean == null ? 0.0 : mean;
    }

    /** Médiane arrondie, ou null pour une liste vide. */
    public static Double medianOrNull(List<? extends Number> values) {
        if (values.isEmpty()) return null;
        List<Double> sorted = new ArrayList<>(values.size());
        for (Number value : values) sorted.add(value.doubleValue());
        Collections.sort(sorted);
        int middle = sorted.size() / 2;
        double median = sorted.size() % 2 == 1
            ? sorted.get(middle)
            : (sorted.get(middle - 1) + sorted.get(middle)) / 2.0;
        return round4(median);
    }
}
