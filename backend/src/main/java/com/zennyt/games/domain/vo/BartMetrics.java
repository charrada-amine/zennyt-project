package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.BartConfig;

import java.util.List;
import java.util.Objects;

/**
 * Trace brute complète du BART : ballons joués dans l'ordre, plus l'état technique
 * de la passation. Aucune valeur calculée n'est acceptée du client.
 */
public record BartMetrics(
    String protocolVersion,
    List<BartBalloonMetric> balloons,
    boolean sessionCompleted,
    boolean interrupted,
    int backgroundEventCount,
    int focusLossCount
) implements GameMetrics {
    public BartMetrics {
        if (!BartConfig.PROTOCOL_VERSION.equals(protocolVersion)) {
            throw new IllegalArgumentException(
                "protocolVersion attendu : " + BartConfig.PROTOCOL_VERSION);
        }
        balloons = List.copyOf(Objects.requireNonNull(balloons, "balloons"));
        if (balloons.isEmpty() || balloons.size() > BartConfig.TOTAL_BALLOON_COUNT) {
            throw new IllegalArgumentException("Nombre de ballons hors protocole");
        }
        for (int i = 0; i < balloons.size(); i++) {
            if (balloons.get(i).balloonIndex() != i) {
                throw new IllegalArgumentException("Les ballons doivent être contigus depuis 0");
            }
        }
        if (backgroundEventCount < 0 || focusLossCount < 0) {
            throw new IllegalArgumentException("Les compteurs techniques doivent être positifs");
        }
        if (sessionCompleted != (balloons.size() == BartConfig.TOTAL_BALLOON_COUNT)) {
            throw new IllegalArgumentException(
                "sessionCompleted incompatible avec le nombre de ballons joués");
        }
    }

    public List<BartBalloonMetric> testBalloons() {
        return balloons.stream().filter(b -> b.phase() == BartPhase.TEST).toList();
    }
}
