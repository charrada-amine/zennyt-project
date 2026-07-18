package com.zennyt.engagement.application.port;

import java.util.UUID;

/**
 * Idempotence de consommation d'événements de domaine côté Engagement.
 *
 * <p>Un {@code eventId} ne doit produire qu'un seul effet, même en cas de rejeu.
 */
public interface ProcessedEventStore {

    /**
     * Réserve atomiquement le traitement d'un événement.
     * @return true si l'événement n'avait pas encore été traité (à traiter),
     *         false s'il l'a déjà été (rejeu → no-op).
     */
    boolean claim(UUID eventId);
}
