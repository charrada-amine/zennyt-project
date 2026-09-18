package com.zennyt.games.domain.vo;

/** Ballon rejoué côté serveur : point d'éclatement réel et points réellement gagnés. */
public record BartBalloonReport(
    int balloonIndex,
    BartPhase phase,
    int explosionPoint,
    int pumpCount,
    BartBalloonOutcome outcome,
    int earnedPoints
) {
}
