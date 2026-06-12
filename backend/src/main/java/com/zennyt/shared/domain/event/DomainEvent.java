package com.zennyt.shared.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Contrat commun à tous les événements de domaine.
 *
 * <p>C'est le pilier du découplage entre bounded contexts : un contexte publie
 * un {@code DomainEvent}, un autre l'écoute — sans jamais s'appeler directement.
 *
 * <p>Aujourd'hui ces événements transitent par l'event bus interne de Spring
 * ({@code ApplicationEventPublisher}). Le jour où un contexte est extrait en
 * microservice, seul l'adaptateur de publication change (Service Bus) :
 * la définition de l'événement et la logique des listeners restent identiques.
 */
public interface DomainEvent {

    /** Identifiant unique de l'occurrence (utile pour l'idempotence). */
    UUID eventId();

    /** Horodatage de survenue. */
    Instant occurredAt();

    /** Type stable, ex : {@code "recruitment.application.submitted"}. */
    String eventType();
}
