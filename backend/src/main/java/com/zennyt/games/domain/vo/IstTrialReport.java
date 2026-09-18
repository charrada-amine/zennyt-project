package com.zennyt.games.domain.vo;

/**
 * Essai IST rejoué côté serveur contre la grille réelle.
 *
 * @param pCorrectAtDecision probabilité que la couleur choisie soit majoritaire au
 *                           vu des cases ouvertes, sous la loi de génération réelle
 */
public record IstTrialReport(
    int trialIndex,
    IstPhase phase,
    IstCondition condition,
    IstColor majorityColor,
    IstColor chosenColor,
    boolean correct,
    int boxesOpened,
    int blueSeen,
    int orangeSeen,
    double pCorrectAtDecision,
    int trialPoints,
    long decisionTimestampMs,
    Integer confidence
) {
}
