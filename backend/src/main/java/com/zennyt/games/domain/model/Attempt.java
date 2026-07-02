package com.zennyt.games.domain.model;

import com.zennyt.games.domain.vo.Score;

import java.time.Instant;

/**
 * Résultat d'un mini-jeu au sein d'une session — entité interne de l'agrégat
 * {@link GameSession}.
 *
 * <p>Immuable une fois enregistré : le score a été calculé par le domaine à
 * partir des métriques, il ne se modifie plus.
 */
public record Attempt(MiniGame miniGame, Score score, Instant recordedAt) {

    public static Attempt of(MiniGame miniGame, Score score) {
        return new Attempt(miniGame, score, Instant.now());
    }
}
