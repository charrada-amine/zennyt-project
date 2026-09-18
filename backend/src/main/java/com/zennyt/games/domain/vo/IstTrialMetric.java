package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.config.IstProvisionalRules;

import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * Trace brute d'un essai IST.
 *
 * @param openings            cases ouvertes, dans l'ordre d'ouverture
 * @param chosenColor         couleur désignée comme majoritaire
 * @param decisionTimestampMs horodatage de la décision depuis l'affichage de la grille
 * @param confidence          1..4 ; null si le joueur a passé (« Passer »)
 */
public record IstTrialMetric(
    int trialIndex,
    IstPhase phase,
    IstCondition condition,
    List<IstBoxOpening> openings,
    IstColor chosenColor,
    long decisionTimestampMs,
    Integer confidence
) {
    public IstTrialMetric {
        Objects.requireNonNull(phase, "phase");
        Objects.requireNonNull(condition, "condition");
        Objects.requireNonNull(chosenColor, "chosenColor");
        openings = List.copyOf(Objects.requireNonNull(openings, "openings"));
        IstConfig.TrialSlot slot = IstConfig.slot(trialIndex);
        if (slot.phase() != phase || slot.condition() != condition) {
            throw new IllegalArgumentException(
                "Phase ou condition incohérente pour l'essai " + trialIndex);
        }
        if (openings.size() > IstConfig.BOX_COUNT) {
            throw new IllegalArgumentException("Trop de cases ouvertes à l'essai " + trialIndex);
        }
        Set<Integer> seen = new HashSet<>();
        long previous = 0L;
        for (IstBoxOpening opening : openings) {
            if (opening.boxIndex() < 0 || opening.boxIndex() >= IstConfig.BOX_COUNT) {
                throw new IllegalArgumentException("Case hors grille : " + opening.boxIndex());
            }
            if (!seen.add(opening.boxIndex())) {
                throw new IllegalArgumentException(
                    "Case ouverte deux fois à l'essai " + trialIndex + " : " + opening.boxIndex());
            }
            if (opening.timestampMs() < previous) {
                throw new IllegalArgumentException(
                    "Ouvertures non chronologiques à l'essai " + trialIndex);
            }
            previous = opening.timestampMs();
        }
        if (decisionTimestampMs < previous) {
            throw new IllegalArgumentException(
                "Décision antérieure à la dernière ouverture à l'essai " + trialIndex);
        }
        if (confidence != null && (confidence < IstProvisionalRules.CONFIDENCE_MIN
            || confidence > IstProvisionalRules.CONFIDENCE_MAX)) {
            throw new IllegalArgumentException("Confiance hors échelle : " + confidence);
        }
    }
}
