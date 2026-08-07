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
 * @param coverageRatio   part des mini-jeux jouables du module réellement jouée
 *                        (0-100). C'est la couverture au sens du CdC Fit Score v3
 *                        §3.3 mécanisme 1 : combien du module a été mesuré, à ne pas
 *                        confondre avec {@code normalizedScore}, qui dit à quel point
 *                        il a été bien joué. Un Planifik où 2 des 3 mini-jeux ont été
 *                        joués vaut 67 % de couverture, quel que soit le score obtenu.
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
    int coverageRatio,
    String level
) implements DomainEvent {

    public static GameResultRecordedEvent of(UUID sessionId, UUID playerId, GameType gameType,
                                             int compositeRaw, int compositeMax,
                                             double normalizedScore, int coverageRatio, String level) {
        return new GameResultRecordedEvent(
            UUID.randomUUID(), Instant.now(), sessionId, playerId, gameType,
            compositeRaw, compositeMax, normalizedScore, coverageRatio, level);
    }

    @Override
    public String eventType() {
        return "games.result.recorded";
    }
}
