package com.zennyt.games.application.command;

import com.zennyt.games.domain.model.MiniGame;
import com.zennyt.games.domain.vo.PlanifikMetrics;

import java.util.UUID;

/**
 * Commande d'entrée : soumettre les métriques d'un mini-jeu terminé.
 *
 * <p>Le client transmet des <b>métriques</b> objectives, jamais un score : le
 * calcul est fait côté serveur par le domaine.
 */
public record SubmitGameResultCommand(
    UUID sessionId,
    MiniGame miniGame,
    PlanifikMetrics metrics
) {}
