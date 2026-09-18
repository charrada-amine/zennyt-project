package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.BartConfig;

import java.util.List;
import java.util.Objects;

/**
 * Trace brute d'un ballon, telle que mesurée par le client.
 *
 * <p>Le client ne déclare JAMAIS le point d'éclatement ni les points gagnés : il
 * déclare combien de fois il a pompé et comment le ballon s'est terminé. Le
 * serveur rejoue cette trace contre sa propre séquence et rejette toute issue
 * impossible ({@code BartActionReplayer}).
 *
 * @param balloonIndex        position dans la séquence, 0-based (0..31)
 * @param phase               doit correspondre à {@link BartConfig#phaseOf(int)}
 * @param pumpCount           pompes effectuées ; si EXPLODED, la dernière a fait éclater
 * @param outcome             COLLECTED ou EXPLODED
 * @param pumpTimestampsMs    horodatage de chaque pompe depuis l'apparition du ballon
 * @param collectTimestampMs  horodatage de la collecte ; null si le ballon a éclaté
 */
public record BartBalloonMetric(
    int balloonIndex,
    BartPhase phase,
    int pumpCount,
    BartBalloonOutcome outcome,
    List<Long> pumpTimestampsMs,
    Long collectTimestampMs
) {
    public BartBalloonMetric {
        Objects.requireNonNull(phase, "phase");
        Objects.requireNonNull(outcome, "outcome");
        pumpTimestampsMs = List.copyOf(Objects.requireNonNull(pumpTimestampsMs, "pumpTimestampsMs"));
        if (phase != BartConfig.phaseOf(balloonIndex)) {
            throw new IllegalArgumentException("Phase incohérente pour le ballon " + balloonIndex);
        }
        if (pumpCount < 0 || pumpCount > BartConfig.MAX_PUMPS) {
            throw new IllegalArgumentException("pumpCount hors bornes : " + pumpCount);
        }
        if (pumpTimestampsMs.size() != pumpCount) {
            throw new IllegalArgumentException(
                "Un horodatage par pompe attendu au ballon " + balloonIndex);
        }
        long previous = 0L;
        for (Long timestamp : pumpTimestampsMs) {
            if (timestamp == null || timestamp < previous) {
                throw new IllegalArgumentException(
                    "Horodatages de pompe non croissants au ballon " + balloonIndex);
            }
            previous = timestamp;
        }
        if (outcome == BartBalloonOutcome.EXPLODED) {
            if (pumpCount == 0) {
                throw new IllegalArgumentException("Un ballon ne peut éclater sans pompe");
            }
            if (collectTimestampMs != null) {
                throw new IllegalArgumentException("Un ballon éclaté n'a pas de collecte");
            }
        } else if (collectTimestampMs == null || collectTimestampMs < previous) {
            throw new IllegalArgumentException(
                "Collecte absente ou antérieure à la dernière pompe au ballon " + balloonIndex);
        }
    }
}
