package com.zennyt.engagement.infrastructure.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zennyt.engagement.application.port.ApplicationEventRetryStore;
import com.zennyt.recruitment.domain.event.MatchCreatedEvent;
import com.zennyt.shared.domain.event.DomainEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ApplicationEventRetryStoreAdapter implements ApplicationEventRetryStore {
    private final JpaPendingApplicationEventRepository jpa;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void enqueue(DomainEvent event, String lastError) {
        Instant now = Instant.now();
        jpa.enqueue(event.eventId(), event.eventType(), serialize(event), safeError(lastError), now);
    }

    @Override
    @Transactional(readOnly = true, propagation = Propagation.REQUIRES_NEW)
    public List<PendingEvent> findDue(Instant now, int limit) {
        return jpa.findByNextAttemptAtLessThanEqualOrderByNextAttemptAtAsc(
                now, PageRequest.of(0, limit)).stream()
            .map(entity -> new PendingEvent(deserialize(entity), entity.getAttempts()))
            .toList();
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void delete(UUID eventId) {
        jpa.deleteById(eventId);
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void reschedule(UUID eventId, Instant nextAttemptAt, String lastError) {
        jpa.reschedule(eventId, nextAttemptAt, safeError(lastError), Instant.now());
    }

    private String serialize(DomainEvent event) {
        try {
            return objectMapper.writeValueAsString(event);
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("Événement Engagement non sérialisable", exception);
        }
    }

    private DomainEvent deserialize(PendingApplicationEventEntity entity) {
        Class<? extends DomainEvent> eventClass = switch (entity.getEventType()) {
            case "recruitment.match.created" -> MatchCreatedEvent.class;
            default -> throw new IllegalStateException(
                "Type d'événement Engagement inconnu: " + entity.getEventType());
        };
        try {
            return objectMapper.readValue(entity.getPayload(), eventClass);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Événement Engagement non désérialisable", exception);
        }
    }

    private String safeError(String error) {
        if (error == null || error.isBlank()) return "Erreur de projection sans message";
        return error.length() <= 2_000 ? error : error.substring(0, 2_000);
    }
}
