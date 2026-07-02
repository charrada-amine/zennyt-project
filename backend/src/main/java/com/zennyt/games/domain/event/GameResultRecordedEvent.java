package com.zennyt.games.domain.event;

import com.zennyt.games.domain.vo.GameType;
import com.zennyt.shared.domain.event.DomainEvent;

import java.time.Instant;
import java.util.UUID;

/**
 * Émis quand une session de jeu est terminée et son score composite calculé.
 *
 * <p>C'est le <b>seul</b> point d'intégration du contexte Games avec le reste
 * de la plateforme. Consommé notamment par Analytics (alimenter le tableau de
 * bord cognitif) et éventuellement Engagement (badges, notifications). Games
 * ignore totalement qui écoute — découplage par contrat d'événement.
 *
 * @param compositeRaw    points bruts cumulés (ex. 0–30 pour Planifik)
 * @param compositeMax    maximum du barème cumulé
 * @param normalizedScore score ramené sur 100
 */
public record GameResultRecordedEvent(
    UUID eventId,
    Instant occurredAt,
    UUID sessionId,
    UUID playerId,
    GameType gameType,
    int compositeRaw,
    int compositeMax,
    double normalizedScore,
    String level
) implements DomainEvent {

    public static GameResultRecordedEvent of(UUID sessionId, UUID playerId, GameType gameType,
                                             int compositeRaw, int compositeMax,
                                             double normalizedScore, String level) {
        return new GameResultRecordedEvent(
            UUID.randomUUID(), Instant.now(), sessionId, playerId, gameType,
            compositeRaw, compositeMax, normalizedScore, level);
    }

    @Override
    public String eventType() {
        return "games.result.recorded";
    }
}
