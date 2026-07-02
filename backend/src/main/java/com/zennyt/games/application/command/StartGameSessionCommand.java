package com.zennyt.games.application.command;

import com.zennyt.games.domain.vo.GameType;

import java.util.UUID;

/** Commande d'entrée : démarrer une session de jeu pour un joueur. */
public record StartGameSessionCommand(UUID playerId, GameType gameType) {}
