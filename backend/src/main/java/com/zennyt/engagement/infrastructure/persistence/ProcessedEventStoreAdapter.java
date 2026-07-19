package com.zennyt.engagement.infrastructure.persistence;

import com.zennyt.engagement.application.port.ProcessedEventStore;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ProcessedEventStoreAdapter implements ProcessedEventStore {
    private final JpaProcessedEventRepository jpa;

    @Override
    public boolean claim(UUID eventId) {
        return jpa.insertIfAbsent(eventId, Instant.now()) == 1;
    }
}
