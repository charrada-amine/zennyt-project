package com.zennyt.games.application.command;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.DeviceCalibration;
import com.zennyt.games.domain.vo.GameMetrics;

import java.util.UUID;

/**
 * Commande d'entrée : soumettre les métriques d'un mini-jeu terminé.
 *
 * <p>Le client transmet des <b>métriques</b> objectives, jamais un score : le
 * calcul est fait côté serveur par le domaine. Le calibrage appareil
 * ({@code deviceCalibration}) est optionnel (null chez les anciens clients).
 */
public record SubmitGameResultCommand(
    UUID sessionId,
    UUID playerId,
    MiniGame miniGame,
    GameMetrics metrics,
    DeviceCalibration deviceCalibration
) {}
