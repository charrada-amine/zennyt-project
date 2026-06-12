package com.zennyt.shared.domain.model;

import com.zennyt.shared.domain.event.DomainEvent;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Classe de base des racines d'agrégat (DDD).
 *
 * <p>Un agrégat enregistre les événements de domaine qu'il produit pendant
 * une transaction métier. La couche application (use case) récupère ces
 * événements après la persistance et les publie sur l'event bus.
 *
 * <p>Cette séparation garantit que les événements ne sont publiés qu'une fois
 * l'état persisté avec succès — pas d'effet de bord sur une transaction annulée.
 */
public abstract class AggregateRoot {

    private final transient List<DomainEvent> domainEvents = new ArrayList<>();

    /** À appeler depuis l'agrégat lorsqu'un fait métier survient. */
    protected void registerEvent(DomainEvent event) {
        this.domainEvents.add(event);
    }

    /** Événements en attente de publication (lecture seule). */
    public List<DomainEvent> domainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    /** Vide la file après publication par la couche application. */
    public void clearEvents() {
        this.domainEvents.clear();
    }
}
